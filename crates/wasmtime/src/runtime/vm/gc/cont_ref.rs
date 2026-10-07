//! Side table for continuation references stored in the GC heap.
//!
//! This follows the same idea as `VMFuncRef` and `externref`. We
//! cannot trust native addresses that come out of the GC heap.

use crate::{Result, bail_bug, vm::VMContObj};
use core::sync::atomic::{AtomicU64, Ordering};
use wasmtime_core::{
    alloc::PanicOnOom,
    slab::{Id, Slab},
};

/// Temporary, opt-in instrumentation for the continuation-reference benchmark.
#[derive(Default)]
struct ContRefTableStats {
    intern_calls: u64,
    null_intern_calls: u64,
    cache_hits: u64,
    cache_misses: u64,
    new_entries: u64,
    backing_storage_growths: u64,
    lookups: AtomicU64,
    peak_len: usize,
    peak_capacity: usize,
}

/// Side table mapping the IDs stored in GC fields to continuation
/// objects.
///
/// Raw ID zero is reserved for a null continuation reference.
/// Non-null IDs are one greater than their underlying slab IDs.
pub struct ContRefTable {
    slab: Slab<VMContObj>,
    epoch: usize,
    stats: Option<ContRefTableStats>,
}

impl Default for ContRefTable {
    fn default() -> Self {
        Self {
            slab: Slab::default(),
            // Epoch zero denotes an empty per-continuation cache.
            epoch: 1,
            stats: std::env::var_os("WASMTIME_CONTREF_TABLE_STATS")
                .map(|_| ContRefTableStats::default()),
        }
    }
}

impl Drop for ContRefTable {
    fn drop(&mut self) {
        let Some(stats) = &self.stats else {
            return;
        };
        eprintln!(
            "continuation-reference table statistics:\n\
             intern calls: {}\n\
             null intern calls: {}\n\
             cache hits: {}\n\
             cache misses: {}\n\
             new side-table entries: {}\n\
             backing-storage growths: {}\n\
             side-table lookups: {}\n\
             peak table length: {}\n\
             peak table capacity: {}",
            stats.intern_calls,
            stats.null_intern_calls,
            stats.cache_hits,
            stats.cache_misses,
            stats.new_entries,
            stats.backing_storage_growths,
            stats.lookups.load(Ordering::Relaxed),
            stats.peak_len,
            stats.peak_capacity,
        );
    }
}

impl ContRefTable {
    /// Intern a continuation object and return the ID to store in the
    /// GC heap.  Null continuation references use the reserved ID
    /// zero.
    ///
    /// # Safety
    ///
    /// A non-null continuation's `VMContRef` pointer must remain valid for the
    /// duration of this table's lifetime.
    pub unsafe fn intern(&mut self, contobj: Option<VMContObj>) -> u32 {
        if let Some(stats) = &mut self.stats {
            stats.intern_calls += 1;
        }

        let Some(contobj) = contobj else {
            if let Some(stats) = &mut self.stats {
                stats.null_intern_calls += 1;
            }
            return 0;
        };

        // SAFETY: The caller guarantees that `contobj.contref` remains valid
        // for the lifetime of this table. These cache fields are exclusively
        // maintained by the runtime while it has mutable access to the store.
        let contref = contobj.contref.as_ptr();
        let cached_epoch = unsafe { (*contref).gc_cached_epoch };
        let cached_revision = unsafe { (*contref).gc_cached_revision };
        if cached_epoch == self.epoch && cached_revision == contobj.revision {
            let cached_id = unsafe { (*contref).gc_cached_id };
            debug_assert_ne!(cached_id, 0);
            if let Some(stats) = &mut self.stats {
                stats.cache_hits += 1;
            }
            return cached_id;
        }

        let capacity_before = self.stats.as_ref().map(|_| self.slab.capacity());

        // TODO(dhil): Handle allocation failure here rather than panicking.
        let id = self.slab.alloc(contobj).panic_on_oom().into_raw();
        let id = id.checked_add(1).unwrap();

        unsafe {
            (*contref).gc_cached_revision = contobj.revision;
            (*contref).gc_cached_epoch = self.epoch;
            (*contref).gc_cached_id = id;
        }

        if let Some(stats) = &mut self.stats {
            let len = self.slab.len();
            let capacity = self.slab.capacity();
            stats.cache_misses += 1;
            stats.new_entries += 1;
            if capacity > capacity_before.unwrap() {
                stats.backing_storage_growths += 1;
            }
            stats.peak_len = stats.peak_len.max(len);
            stats.peak_capacity = stats.peak_capacity.max(capacity);
        }

        id
    }

    /// Resolve an ID loaded from the GC heap.
    pub fn get(&self, raw: u32) -> Result<Option<VMContObj>> {
        if let Some(stats) = &self.stats {
            stats.lookups.fetch_add(1, Ordering::Relaxed);
        }

        if raw == 0 {
            return Ok(None);
        }

        let contobj = Id::try_from_raw(raw - 1).and_then(|id| self.slab.get(id).copied());
        match contobj {
            Some(contobj) => Ok(Some(contobj)),
            None => bail_bug!("bad continuation-reference table ID"),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::vm::VMContRef;
    use core::ptr::NonNull;
    use std::boxed::Box;

    #[test]
    fn caches_only_the_most_recent_revision() {
        let mut contref = Box::new(VMContRef::empty());
        let contref = NonNull::from(&mut *contref);
        let mut table = ContRefTable::default();

        let revision_zero = VMContObj::new(contref, 0);
        let first_id = unsafe { table.intern(Some(revision_zero)) };
        assert_ne!(first_id, 0);
        assert_eq!(unsafe { table.intern(Some(revision_zero)) }, first_id);
        assert_eq!(table.slab.len(), 1);

        let revision_one = VMContObj::new(contref, 1);
        let second_id = unsafe { table.intern(Some(revision_one)) };
        assert_ne!(second_id, first_id);
        assert_eq!(unsafe { table.intern(Some(revision_one)) }, second_id);
        assert_eq!(table.slab.len(), 2);

        // The cache contains only the most recently interned revision. An old
        // alias remains stale and valid to store, but requires a new entry.
        let third_id = unsafe { table.intern(Some(revision_zero)) };
        assert_ne!(third_id, first_id);
        assert_ne!(third_id, second_id);
        assert_eq!(table.slab.len(), 3);

        assert_eq!(table.get(first_id).unwrap(), Some(revision_zero));
        assert_eq!(table.get(second_id).unwrap(), Some(revision_one));
        assert_eq!(table.get(third_id).unwrap(), Some(revision_zero));
    }

    #[test]
    fn null_uses_reserved_zero_id() {
        let mut table = ContRefTable::default();
        assert_eq!(unsafe { table.intern(None) }, 0);
        assert_eq!(table.get(0).unwrap(), None);
        assert!(table.slab.is_empty());
    }
}
