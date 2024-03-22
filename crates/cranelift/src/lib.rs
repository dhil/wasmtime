//! Support for compiling with Cranelift.
//!
//! This crate provides an implementation of the `wasmtime_environ::Compiler`
//! and `wasmtime_environ::CompilerBuilder` traits.

use cranelift_codegen::{
    binemit,
    ir::{self, ExternalName, UserExternalNameRef},
    isa::{CallConv, TargetIsa},
    settings, FinalizedMachReloc, FinalizedRelocTarget, MachTrap,
};
use cranelift_entity::PrimaryMap;
use cranelift_wasm::{DefinedFuncIndex, FuncIndex, WasmFuncType, WasmValType};
use target_lexicon::Architecture;

pub use builder::builder;
use wasmtime_environ::{FlagValue, Trap, TrapInformation, Tunables};

pub mod isa_builder;
mod obj;
pub use obj::*;
mod compiled_function;
pub use compiled_function::*;

mod builder;
mod compiler;
mod debug;
mod func_environ;
mod wasmfx;

type CompiledFunctionsMetadata<'a> = PrimaryMap<DefinedFuncIndex, &'a CompiledFunctionMetadata>;

/// Trap code used for debug assertions we emit in our JIT code.
const DEBUG_ASSERT_TRAP_CODE: u16 = u16::MAX;

/// Creates a new cranelift `Signature` with no wasm params/results for the
/// given calling convention.
///
/// This will add the default vmctx/etc parameters to the signature returned.
fn blank_sig(isa: &dyn TargetIsa, call_conv: CallConv) -> ir::Signature {
    let pointer_type = isa.pointer_type();
    let mut sig = ir::Signature::new(call_conv);
    // Add the caller/callee `vmctx` parameters.
    sig.params.push(ir::AbiParam::special(
        pointer_type,
        ir::ArgumentPurpose::VMContext,
    ));
    sig.params.push(ir::AbiParam::new(pointer_type));
    return sig;
}

/// Returns the corresponding cranelift type for the provided wasm type.
fn value_type(isa: &dyn TargetIsa, ty: WasmValType) -> ir::types::Type {
    match ty {
        WasmValType::I32 => ir::types::I32,
        WasmValType::I64 => ir::types::I64,
        WasmValType::F32 => ir::types::F32,
        WasmValType::F64 => ir::types::F64,
        WasmValType::V128 => ir::types::I8X16,
        WasmValType::Ref(rt) => reference_type(rt.heap_type, isa.pointer_type()),
    }
}

/// Get the Cranelift signature with the native calling convention for the given
/// Wasm function type.
///
/// This parameters will start with the callee and caller VM contexts, followed
/// by the translation of each of the Wasm parameter types to native types. The
/// results are the Wasm result types translated to native types.
///
/// The signature uses the wasmtime variant of the target's default calling
/// convention. The only difference from the default calling convention is how
/// multiple results are handled.
///
/// When there is only a single result, or zero results, these signatures are
/// suitable for calling from the host via
///
/// ```ignore
/// unsafe extern "C" fn(
///     callee_vmctx: *mut VMOpaqueContext,
///     caller_vmctx: *mut VMOpaqueContext,
///     // ...wasm parameter types...
/// ) -> // ...wasm result type...
/// ```
///
/// When there are more than one results, these signatures are suitable for
/// calling from the host via
///
/// ```ignore
/// unsafe extern "C" fn(
///     callee_vmctx: *mut VMOpaqueContext,
///     caller_vmctx: *mut VMOpaqueContext,
///     // ...wasm parameter types...
///     retptr: *mut (),
/// ) -> // ...wasm result type 0...
/// ```
///
/// where the first result is returned directly and the rest via the return
/// pointer.
fn native_call_signature(isa: &dyn TargetIsa, wasm: &WasmFuncType) -> ir::Signature {
    let mut sig = blank_sig(isa, CallConv::triple_default(isa.triple()));
    let cvt = |ty: &WasmValType| ir::AbiParam::new(value_type(isa, *ty));
    sig.params.extend(wasm.params().iter().map(&cvt));
    if let Some(first_ret) = wasm.returns().get(0) {
        sig.returns.push(cvt(first_ret));
    }
    if wasm.returns().len() > 1 {
        sig.params.push(ir::AbiParam::new(isa.pointer_type()));
    }
    sig
}

/// Get the Cranelift signature for all array-call functions, that is:
///
/// ```ignore
/// unsafe extern "C" fn(
///     callee_vmctx: *mut VMOpaqueContext,
///     caller_vmctx: *mut VMOpaqueContext,
///     values_ptr: *mut ValRaw,
///     values_len: usize,
/// )
/// ```
///
/// This signature uses the target's default calling convention.
///
/// Note that regardless of the Wasm function type, the array-call calling
/// convention always uses that same signature.
fn array_call_signature(isa: &dyn TargetIsa) -> ir::Signature {
    let mut sig = blank_sig(isa, CallConv::triple_default(isa.triple()));
    // The array-call signature has an added parameter for the `values_vec`
    // input/output buffer in addition to the size of the buffer, in units
    // of `ValRaw`.
    sig.params.push(ir::AbiParam::new(isa.pointer_type()));
    sig.params.push(ir::AbiParam::new(isa.pointer_type()));
    sig
}

/// Get the internal Wasm calling convention signature for the given type.
fn wasm_call_signature(
    isa: &dyn TargetIsa,
    wasm_func_ty: &WasmFuncType,
    tunables: &Tunables,
) -> ir::Signature {
    // NB: this calling convention in the near future is expected to be
    // unconditionally switched to the "tail" calling convention once all
    // platforms have support for tail calls.
    //
    // Also note that the calling convention for wasm functions is purely an
    // internal implementation detail of cranelift and Wasmtime. Native Rust
    // code does not interact with raw wasm functions and instead always
    // operates through trampolines either using the `array_call_signature` or
    // `native_call_signature` where the default platform ABI is used.
    let call_conv = match isa.triple().architecture {
        // If the tail calls proposal is enabled, we must use the tail calling
        // convention. We don't use it by default yet because of
        // https://github.com/bytecodealliance/wasmtime/issues/6759
        arch if tunables.tail_callable => {
            assert_ne!(
                arch,
                Architecture::S390x,
                "https://github.com/bytecodealliance/wasmtime/issues/6530"
            );
            CallConv::Tail
        }

        // The winch calling convention is only implemented for x64 and aarch64
        arch if tunables.winch_callable => {
            assert!(
                matches!(arch, Architecture::X86_64),
                "The Winch calling convention is only implemented for x86_64"
            );
            CallConv::Winch
        }

        // On s390x the "wasmtime" calling convention is used to give vectors
        // little-endian lane order at the ABI layer which should reduce the
        // need for conversion when operating on vector function arguments. By
        // default vectors on s390x are otherwise in big-endian lane order which
        // would require conversions.
        Architecture::S390x => CallConv::WasmtimeSystemV,

        // All other platforms pick "fast" as the calling convention since it's
        // presumably, well, the fastest.
        _ => CallConv::Fast,
    };
    let mut sig = blank_sig(isa, call_conv);
    let cvt = |ty: &WasmValType| ir::AbiParam::new(value_type(isa, *ty));
    sig.params.extend(wasm_func_ty.params().iter().map(&cvt));
    sig.returns.extend(wasm_func_ty.returns().iter().map(&cvt));
    sig
}

/// Returns the reference type to use for the provided wasm type.
fn reference_type(wasm_ht: cranelift_wasm::WasmHeapType, pointer_type: ir::Type) -> ir::Type {
    match wasm_ht {
        cranelift_wasm::WasmHeapType::Func
        | cranelift_wasm::WasmHeapType::Concrete(_)
        | cranelift_wasm::WasmHeapType::NoFunc
        | cranelift_wasm::WasmHeapType::Cont
        | cranelift_wasm::WasmHeapType::NoCont => pointer_type,
        cranelift_wasm::WasmHeapType::Extern => match pointer_type {
            ir::types::I32 => ir::types::R32,
            ir::types::I64 => ir::types::R64,
            _ => panic!("unsupported pointer type"),
        },
    }
}

/// A record of a relocation to perform.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Relocation {
    /// The relocation code.
    pub reloc: binemit::Reloc,
    /// Relocation target.
    pub reloc_target: RelocationTarget,
    /// The offset where to apply the relocation.
    pub offset: binemit::CodeOffset,
    /// The addend to add to the relocation value.
    pub addend: binemit::Addend,
}

/// Destination function. Can be either user function or some special one, like `memory.grow`.
#[derive(Debug, Copy, Clone, PartialEq, Eq)]
pub enum RelocationTarget {
    /// The user function index.
    UserFunc(FuncIndex),
    /// A compiler-generated libcall.
    LibCall(ir::LibCall),
}

/// Converts cranelift_codegen settings to the wasmtime_environ equivalent.
pub fn clif_flags_to_wasmtime(
    flags: impl IntoIterator<Item = settings::Value>,
) -> Vec<(&'static str, FlagValue<'static>)> {
    flags
        .into_iter()
        .map(|val| (val.name, to_flag_value(&val)))
        .collect()
}

fn to_flag_value(v: &settings::Value) -> FlagValue<'static> {
    match v.kind() {
        settings::SettingKind::Enum => FlagValue::Enum(v.as_enum().unwrap()),
        settings::SettingKind::Num => FlagValue::Num(v.as_num().unwrap()),
        settings::SettingKind::Bool => FlagValue::Bool(v.as_bool().unwrap()),
        settings::SettingKind::Preset => unreachable!(),
    }
}

/// A custom code with `TrapCode::User` which is used by always-trap shims which
/// indicates that, as expected, the always-trapping function indeed did trap.
/// This effectively provides a better error message as opposed to a bland
/// "unreachable code reached"
pub const ALWAYS_TRAP_CODE: u16 = 100;

/// A custom code with `TrapCode::User` corresponding to being unable to reenter
/// a component due to its reentrance limitations. This is used in component
/// adapters to provide a more useful error message in such situations.
pub const CANNOT_ENTER_CODE: u16 = 101;

/// Converts machine traps to trap information.
pub fn mach_trap_to_trap(trap: &MachTrap) -> Option<TrapInformation> {
    let &MachTrap { offset, code } = trap;
    Some(TrapInformation {
        code_offset: offset,
        trap_code: match code {
            ir::TrapCode::StackOverflow => Trap::StackOverflow,
            ir::TrapCode::HeapOutOfBounds => Trap::MemoryOutOfBounds,
            ir::TrapCode::HeapMisaligned => Trap::HeapMisaligned,
            ir::TrapCode::TableOutOfBounds => Trap::TableOutOfBounds,
            ir::TrapCode::IndirectCallToNull => Trap::IndirectCallToNull,
            ir::TrapCode::BadSignature => Trap::BadSignature,
            ir::TrapCode::IntegerOverflow => Trap::IntegerOverflow,
            ir::TrapCode::IntegerDivisionByZero => Trap::IntegerDivisionByZero,
            ir::TrapCode::BadConversionToInteger => Trap::BadConversionToInteger,
            ir::TrapCode::UnreachableCodeReached => Trap::UnreachableCodeReached,
            ir::TrapCode::Interrupt => Trap::Interrupt,
            ir::TrapCode::User(ALWAYS_TRAP_CODE) => Trap::AlwaysTrapAdapter,
            ir::TrapCode::User(CANNOT_ENTER_CODE) => Trap::CannotEnterComponent,
            ir::TrapCode::NullReference => Trap::NullReference,

            // These do not get converted to wasmtime traps, since they
            // shouldn't ever be hit in theory. Instead of catching and handling
            // these, we let the signal crash the process.
            ir::TrapCode::User(DEBUG_ASSERT_TRAP_CODE) => return None,

            // these should never be emitted by wasmtime-cranelift
            ir::TrapCode::User(_) => unreachable!(),
        },
    })
}

/// Converts machine relocations to relocation information
/// to perform.
fn mach_reloc_to_reloc<F>(reloc: &FinalizedMachReloc, transform_user_func_ref: F) -> Relocation
where
    F: Fn(UserExternalNameRef) -> (u32, u32),
{
    let &FinalizedMachReloc {
        offset,
        kind,
        ref target,
        addend,
    } = reloc;
    let reloc_target = match *target {
        FinalizedRelocTarget::ExternalName(ExternalName::User(user_func_ref)) => {
            let (namespace, index) = transform_user_func_ref(user_func_ref);
            debug_assert_eq!(namespace, 0);
            RelocationTarget::UserFunc(FuncIndex::from_u32(index))
        }
        FinalizedRelocTarget::ExternalName(ExternalName::LibCall(libcall)) => {
            RelocationTarget::LibCall(libcall)
        }
        _ => panic!("unrecognized external name"),
    };
    Relocation {
        reloc: kind,
        reloc_target,
        offset,
        addend,
    }
}
