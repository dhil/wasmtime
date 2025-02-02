use std::io;
use std::ops::Range;

use wasmtime_environ::stack_switching::Array;

use crate::runtime::vm::{VMContext, VMFuncRef, ValRaw};

#[derive(Debug)]
pub struct ContinuationStack {}

impl ContinuationStack {
    pub fn new(_size: usize) -> io::Result<Self> {
        panic!("Stack switching is not implemented on this platform")
    }

    pub fn unallocated() -> Self {
        panic!("Stack switching is not implemented on this platform")
    }

    pub fn is_unallocated(&self) -> bool {
        panic!("Stack switching is not implemented on this platform")
    }

    #[allow(clippy::missing_safety_doc)]
    pub unsafe fn from_raw_parts(
        _base: *mut u8,
        _guard_size: usize,
        _len: usize,
    ) -> io::Result<Self> {
        panic!("Stack switching is not implemented on this platform")
    }

    pub fn is_from_raw_parts(&self) -> bool {
        panic!("Stack switching is not implemented on this platform")
    }

    pub fn top(&self) -> Option<*mut u8> {
        panic!("Stack switching is not implemented on this platform")
    }

    pub fn range(&self) -> Option<Range<usize>> {
        panic!("Stack switching is not implemented on this platform")
    }

    pub fn control_context_instruction_pointer(&self) -> usize {
        panic!("Stack switching is not implemented on this platform")
    }

    pub fn control_context_frame_pointer(&self) -> usize {
        panic!("Stack switching is not implemented on this platform")
    }

    pub fn control_context_stack_pointer(&self) -> usize {
        panic!("Stack switching is not implemented on this platform")
    }

    pub fn initialize(
        &self,
        _func_ref: *const VMFuncRef,
        _caller_vmctx: *mut VMContext,
        _args: *mut Array<ValRaw>,
        _parameter_count: u32,
        _return_value_count: u32,
    ) {
        panic!("Stack switching is not implemented on this platform")
    }
}
