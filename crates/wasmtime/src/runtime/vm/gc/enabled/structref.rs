use crate::{
    prelude::*,
    runtime::vm::{GcHeap, GcStore, VMGcRef},
    store::AutoAssertNoGc,
    vm::GcStructLayout,
    AnyRef, ExternRef, HeapType, RootedGcRefImpl, StorageType, Val, ValType, V128,
};
use core::{fmt, mem};
use wasmtime_environ::VMGcKind;

/// A `VMGcRef` that we know points to a `struct`.
///
/// Create a `VMStructRef` via `VMGcRef::into_structref` and
/// `VMGcRef::as_structref`, or their untyped equivalents
/// `VMGcRef::into_structref_unchecked` and `VMGcRef::as_structref_unchecked`.
///
/// Note: This is not a `TypedGcRef<_>` because each collector can have a
/// different concrete representation of `structref` that they allocate inside
/// their heaps.
#[derive(Debug, PartialEq, Eq, Hash)]
#[repr(transparent)]
pub struct VMStructRef(VMGcRef);

impl fmt::Pointer for VMStructRef {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        fmt::Pointer::fmt(&self.0, f)
    }
}

impl From<VMStructRef> for VMGcRef {
    #[inline]
    fn from(x: VMStructRef) -> Self {
        x.0
    }
}

impl VMGcRef {
    /// Is this `VMGcRef` pointing to a `struct`?
    pub fn is_structref(&self, gc_heap: &(impl GcHeap + ?Sized)) -> bool {
        if self.is_i31() {
            return false;
        }

        let header = gc_heap.header(&self);
        header.kind().matches(VMGcKind::StructRef)
    }

    /// Create a new `VMStructRef` from the given `gc_ref`.
    ///
    /// If this is not a GC reference to an `structref`, `Err(self)` is
    /// returned.
    pub fn into_structref(self, gc_heap: &impl GcHeap) -> Result<VMStructRef, VMGcRef> {
        if self.is_structref(gc_heap) {
            Ok(self.into_structref_unchecked())
        } else {
            Err(self)
        }
    }

    /// Create a new `VMStructRef` from `self` without actually checking that
    /// `self` is an `structref`.
    ///
    /// This method does not check that `self` is actually an `structref`, but
    /// it should be. Failure to uphold this invariant is memory safe but will
    /// result in general incorrectness down the line such as panics or wrong
    /// results.
    #[inline]
    pub fn into_structref_unchecked(self) -> VMStructRef {
        debug_assert!(!self.is_i31());
        VMStructRef(self)
    }

    /// Get this GC reference as an `structref` reference, if it actually is an
    /// `structref` reference.
    pub fn as_structref(&self, gc_heap: &(impl GcHeap + ?Sized)) -> Option<&VMStructRef> {
        if self.is_structref(gc_heap) {
            Some(self.as_structref_unchecked())
        } else {
            None
        }
    }

    /// Get this GC reference as an `structref` reference without checking if it
    /// actually is an `structref` reference.
    ///
    /// Calling this method on a non-`structref` reference is memory safe, but
    /// will lead to general incorrectness like panics and wrong results.
    pub fn as_structref_unchecked(&self) -> &VMStructRef {
        debug_assert!(!self.is_i31());
        let ptr = self as *const VMGcRef;
        let ret = unsafe { &*ptr.cast() };
        assert!(matches!(ret, VMStructRef(VMGcRef { .. })));
        ret
    }
}

impl VMStructRef {
    /// Get the underlying `VMGcRef`.
    pub fn as_gc_ref(&self) -> &VMGcRef {
        &self.0
    }

    /// Clone this `VMStructRef`, running any GC barriers as necessary.
    pub fn clone(&self, gc_store: &mut GcStore) -> Self {
        Self(gc_store.clone_gc_ref(&self.0))
    }

    /// Explicitly drop this `structref`, running GC drop barriers as necessary.
    pub fn drop(self, gc_store: &mut GcStore) {
        gc_store.drop_gc_ref(self.0);
    }

    /// Copy this `VMStructRef` without running the GC's clone barriers.
    ///
    /// Prefer calling `clone(&mut GcStore)` instead! This is mostly an internal
    /// escape hatch for collector implementations.
    ///
    /// Failure to run GC barriers when they would otherwise be necessary can
    /// lead to leaks, panics, and wrong results. It cannot lead to memory
    /// unsafety, however.
    pub fn unchecked_copy(&self) -> Self {
        Self(self.0.unchecked_copy())
    }

    /// Read a field of the given `StorageType` into a `Val`.
    ///
    /// `i8` and `i16` fields are zero-extended into `Val::I32(_)`s.
    ///
    /// Does not check that the field is actually of type `ty`. That is the
    /// caller's responsibility. Failure to do so is memory safe, but will lead
    /// to general incorrectness such as panics and wrong results.
    ///
    /// Panics on out-of-bounds accesses.
    pub fn read_field(
        &self,
        store: &mut AutoAssertNoGc,
        layout: &GcStructLayout,
        ty: &StorageType,
        field: usize,
    ) -> Val {
        let offset = layout.fields[field];
        let data = store.unwrap_gc_store_mut().struct_data(self, layout.size);
        match ty {
            StorageType::I8 => Val::I32(data.read_u8(offset).into()),
            StorageType::I16 => Val::I32(data.read_u16(offset).into()),
            StorageType::ValType(ValType::I32) => Val::I32(data.read_i32(offset)),
            StorageType::ValType(ValType::I64) => Val::I64(data.read_i64(offset)),
            StorageType::ValType(ValType::F32) => Val::F32(data.read_u32(offset)),
            StorageType::ValType(ValType::F64) => Val::F64(data.read_u64(offset)),
            StorageType::ValType(ValType::V128) => Val::V128(data.read_v128(offset)),
            StorageType::ValType(ValType::Ref(r)) => match r.heap_type().top() {
                HeapType::Extern => {
                    let raw = data.read_u32(offset);
                    Val::ExternRef(ExternRef::_from_raw(store, raw))
                }
                HeapType::Any => {
                    let raw = data.read_u32(offset);
                    Val::AnyRef(AnyRef::_from_raw(store, raw))
                }
                HeapType::Func => todo!("funcrefs inside gc objects not yet implemented"),
                otherwise => unreachable!("not a top type: {otherwise:?}"),
            },
        }
    }

    /// Write the given value into this struct at the given offset.
    ///
    /// Returns an error if `val` is a GC reference that has since been
    /// unrooted.
    ///
    /// Does not check that `val` matches `ty`, nor that the field is actually
    /// of type `ty`. Checking those things is the caller's responsibility.
    /// Failure to do so is memory safe, but will lead to general incorrectness
    /// such as panics and wrong results.
    ///
    /// Panics on out-of-bounds accesses.
    pub fn write_field(
        &self,
        store: &mut AutoAssertNoGc,
        layout: &GcStructLayout,
        ty: &StorageType,
        field: usize,
        val: Val,
    ) -> Result<()> {
        debug_assert!(val._matches_ty(&store, &ty.unpack())?);

        let offset = layout.fields[field];
        let mut data = store.gc_store_mut()?.struct_data(self, layout.size);
        match val {
            Val::I32(i) if ty.is_i8() => data.write_i8(offset, i as i8),
            Val::I32(i) if ty.is_i16() => data.write_i16(offset, i as i16),
            Val::I32(i) => data.write_i32(offset, i),
            Val::I64(i) => data.write_i64(offset, i),
            Val::F32(f) => data.write_u32(offset, f),
            Val::F64(f) => data.write_u64(offset, f),
            Val::V128(v) => data.write_v128(offset, v),

            // For GC-managed references, we need to take care to run the
            // appropriate barriers, even when we are writing null references
            // into the struct.
            //
            // POD-read the old value into a local copy, run the GC write
            // barrier on that local copy, and then POD-write the updated
            // value back into the struct. This avoids transmuting the inner
            // data, which would probably be fine, but this approach is
            // Obviously Correct and should get us by for now. If LLVM isn't
            // able to elide some of these unnecessary copies, and this
            // method is ever hot enough, we can always come back and clean
            // it up in the future.
            Val::ExternRef(e) => {
                let raw = data.read_u32(offset);
                let mut gc_ref = VMGcRef::from_raw_u32(raw);
                let e = match e {
                    Some(e) => Some(e.try_gc_ref(store)?.unchecked_copy()),
                    None => None,
                };
                store.gc_store_mut()?.write_gc_ref(&mut gc_ref, e.as_ref());
                let mut data = store.gc_store_mut()?.struct_data(self, layout.size);
                data.write_u32(offset, gc_ref.map_or(0, |r| r.as_raw_u32()));
            }
            Val::AnyRef(a) => {
                let raw = data.read_u32(offset);
                let mut gc_ref = VMGcRef::from_raw_u32(raw);
                let a = match a {
                    Some(a) => Some(a.try_gc_ref(store)?.unchecked_copy()),
                    None => None,
                };
                store.gc_store_mut()?.write_gc_ref(&mut gc_ref, a.as_ref());
                let mut data = store.gc_store_mut()?.struct_data(self, layout.size);
                data.write_u32(offset, gc_ref.map_or(0, |r| r.as_raw_u32()));
            }

            Val::FuncRef(_) => todo!("funcrefs inside gc objects not yet implemented"),
        }
        Ok(())
    }

    /// Initialize a field in this structref that is currently uninitialized.
    ///
    /// The difference between this method and `write_field` is that GC barriers
    /// are handled differently. When overwriting an initialized field (aka
    /// `write_field`) we need to call the full write GC write barrier, which
    /// logically drops the old GC reference and clones the new GC
    /// reference. When we are initializing a field for the first time, there is
    /// no old GC reference that is being overwritten and which we need to drop,
    /// so we only need to clone the new GC reference.
    ///
    /// Calling this method on a structref that has already had the associated
    /// field initialized will result in GC bugs. These are memory safe but will
    /// lead to generally incorrect behavior such as panics, leaks, and
    /// incorrect results.
    ///
    /// Does not check that `val` matches `ty`, nor that the field is actually
    /// of type `ty`. Checking those things is the caller's responsibility.
    /// Failure to do so is memory safe, but will lead to general incorrectness
    /// such as panics and wrong results.
    ///
    /// Returns an error if `val` is a GC reference that has since been
    /// unrooted.
    ///
    /// Panics on out-of-bounds accesses.
    pub fn initialize_field(
        &self,
        store: &mut AutoAssertNoGc,
        layout: &GcStructLayout,
        ty: &StorageType,
        field: usize,
        val: Val,
    ) -> Result<()> {
        debug_assert!(val._matches_ty(&store, &ty.unpack())?);
        let offset = layout.fields[field];
        match val {
            Val::I32(i) if ty.is_i8() => store
                .gc_store_mut()?
                .struct_data(self, layout.size)
                .write_i8(offset, i as i8),
            Val::I32(i) if ty.is_i16() => store
                .gc_store_mut()?
                .struct_data(self, layout.size)
                .write_i16(offset, i as i16),
            Val::I32(i) => store
                .gc_store_mut()?
                .struct_data(self, layout.size)
                .write_i32(offset, i),
            Val::I64(i) => store
                .gc_store_mut()?
                .struct_data(self, layout.size)
                .write_i64(offset, i),
            Val::F32(f) => store
                .gc_store_mut()?
                .struct_data(self, layout.size)
                .write_u32(offset, f),
            Val::F64(f) => store
                .gc_store_mut()?
                .struct_data(self, layout.size)
                .write_u64(offset, f),
            Val::V128(v) => store
                .gc_store_mut()?
                .struct_data(self, layout.size)
                .write_v128(offset, v),

            // NB: We don't need to do a write barrier when initializing a
            // field, because there is nothing being overwritten. Therefore, we
            // just the clone barrier.
            Val::ExternRef(x) => {
                let x = match x {
                    None => 0,
                    Some(x) => x.try_clone_gc_ref(store)?.as_raw_u32(),
                };
                store
                    .gc_store_mut()?
                    .struct_data(self, layout.size)
                    .write_u32(offset, x);
            }
            Val::AnyRef(x) => {
                let x = match x {
                    None => 0,
                    Some(x) => x.try_clone_gc_ref(store)?.as_raw_u32(),
                };
                store
                    .gc_store_mut()?
                    .struct_data(self, layout.size)
                    .write_u32(offset, x);
            }

            Val::FuncRef(_) => {
                // TODO: we can't trust the GC heap, which means we can't read
                // native VMFuncRef pointers out of it and trust them. That
                // means we need to do the same side table kind of thing we do
                // with `externref` host data here. This isn't implemented yet.
                todo!("funcrefs in GC objects")
            }
        }
        Ok(())
    }
}

/// A plain-old-data type that can be stored in a `ValType` or a `StorageType`.
///
/// Safety: implementations must be POD and all bit patterns must be valid.
pub trait PodValType<const SIZE: usize>: Copy {
    /// Read an instance of `Self` from the given little-endian bytes.
    fn read_le(le_bytes: &[u8; SIZE]) -> Self;

    /// Write `self` into the given memory location, as little-endian bytes.
    fn write_le(&self, into: &mut [u8; SIZE]);
}

macro_rules! impl_pod_val_type {
    ( $( $t:ty , )* ) => {
        $(
            impl PodValType<{core::mem::size_of::<$t>()}> for $t {
                fn read_le(le_bytes: &[u8; core::mem::size_of::<$t>()]) -> Self {
                    <$t>::from_le_bytes(*le_bytes)
                }
                fn write_le(&self, into: &mut [u8; core::mem::size_of::<$t>()]) {
                    *into = self.to_le_bytes();
                }
            }
        )*
    };
}

impl_pod_val_type! {
    u8,
    u16,
    u32,
    u64,
    i8,
    i16,
    i32,
    i64,
}

impl PodValType<{ mem::size_of::<V128>() }> for V128 {
    fn read_le(le_bytes: &[u8; mem::size_of::<V128>()]) -> Self {
        u128::from_le_bytes(*le_bytes).into()
    }
    fn write_le(&self, into: &mut [u8; mem::size_of::<V128>()]) {
        *into = self.as_u128().to_le_bytes();
    }
}

/// The backing storage for a GC-managed struct.
///
/// Methods on this type do not, generally, check against things like type
/// mismatches or that the given offset to read from even falls on a field
/// boundary. Omitting these checks is memory safe, due to our untrusted,
/// indexed GC heaps. Providing incorrect offsets will result in general
/// incorrectness, such as wrong answers or even panics, however.
///
/// Finally, these methods *will* panic on out-of-bounds accesses, either out of
/// the GC heap's bounds or out of this struct's bounds. The former is necessary
/// for preserving the memory safety of indexed GC heaps in the face of (for
/// example) collector bugs, but the latter is just a defensive technique to
/// catch bugs early and prevent action at a distance as much as possible.
pub struct VMStructDataMut<'a> {
    data: &'a mut [u8],
}

macro_rules! impl_pod_methods {
    ( $( $t:ty, $read:ident, $write:ident; )* ) => {
        $(
            /// Read from a `
            #[doc = stringify!($t)]
            /// ` field in this struct.
            ///
            /// Panics on out-of-bounds accesses.
            #[inline]
            pub fn $read(&self, offset: u32) -> $t {
                self.read_pod::<{ mem::size_of::<$t>() }, $t>(offset)
            }

            /// Write to a `
            #[doc = stringify!($t)]
            /// ` field in this struct.
            ///
            /// Panics on out-of-bounds accesses.
            #[inline]
            pub fn $write(&mut self, offset: u32, val: $t) {
                self.write_pod::<{ mem::size_of::<$t>() }, $t>(offset, val);
            }
        )*
    };
}

impl<'a> VMStructDataMut<'a> {
    /// Construct a `VMStructDataMut` from the given slice of bytes.
    #[inline]
    pub fn new(data: &'a mut [u8]) -> Self {
        Self { data }
    }

    /// Read a POD field out of this struct.
    ///
    /// Panics on out-of-bounds accesses.
    ///
    /// Don't generally use this method, use `read_u8`, `read_i64`,
    /// etc... instead.
    #[inline]
    fn read_pod<const N: usize, T>(&self, offset: u32) -> T
    where
        T: PodValType<N>,
    {
        assert_eq!(N, mem::size_of::<T>());
        let offset = usize::try_from(offset).unwrap();
        let end = offset.checked_add(N).unwrap();
        let bytes = self.data.get(offset..end).expect("out of bounds field");
        T::read_le(bytes.try_into().unwrap())
    }

    /// Read a POD field out of this struct.
    ///
    /// Panics on out-of-bounds accesses.
    ///
    /// Don't generally use this method, use `write_u8`, `write_i64`,
    /// etc... instead.
    #[inline]
    fn write_pod<const N: usize, T>(&mut self, offset: u32, val: T)
    where
        T: PodValType<N>,
    {
        assert_eq!(N, mem::size_of::<T>());
        let offset = usize::try_from(offset).unwrap();
        let end = offset.checked_add(N).unwrap();
        let into = self.data.get_mut(offset..end).expect("out of bounds field");
        val.write_le(into.try_into().unwrap());
    }

    impl_pod_methods! {
        u8, read_u8, write_u8;
        u16, read_u16, write_u16;
        u32, read_u32, write_u32;
        u64, read_u64, write_u64;
        i8, read_i8, write_i8;
        i16, read_i16, write_i16;
        i32, read_i32, write_i32;
        i64, read_i64, write_i64;
        V128, read_v128, write_v128;
    }
}
