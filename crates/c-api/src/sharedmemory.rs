use crate::{handle_result, wasm_memorytype_t, wasmtime_error_t, wasmtime_extern_t};
use std::cell::UnsafeCell;
use std::mem::MaybeUninit;
use wasmtime::{Extern, SharedMemory};

type wasmtime_sharedmemory_t = SharedMemory;

wasmtime_c_api_macros::declare_own!(wasmtime_sharedmemory_t);

#[no_mangle]
#[cfg(feature = "threads")]
pub extern "C" fn wasmtime_sharedmemory_new(
    engine: &crate::wasm_engine_t,
    ty: &wasm_memorytype_t,
    ret: &mut *mut wasmtime_sharedmemory_t,
) -> Option<Box<wasmtime_error_t>> {
    handle_result(
        SharedMemory::new(&engine.engine, ty.ty().ty.clone()),
        |mem| *ret = Box::<wasmtime_sharedmemory_t>::into_raw(Box::new(mem)),
    )
}

#[no_mangle]
pub extern "C" fn wasmtime_sharedmemory_clone(
    mem: &wasmtime_sharedmemory_t,
) -> Box<wasmtime_sharedmemory_t> {
    Box::new(mem.clone())
}

#[no_mangle]
pub extern "C" fn wasmtime_sharedmemory_into_extern(
    mem: Box<wasmtime_sharedmemory_t>,
    ext: &mut MaybeUninit<wasmtime_extern_t>,
) {
    crate::initialize(ext, Extern::from(*mem).into());
}

#[no_mangle]
pub extern "C" fn wasmtime_sharedmemory_type(
    mem: &wasmtime_sharedmemory_t,
) -> Box<wasm_memorytype_t> {
    Box::new(wasm_memorytype_t::new(mem.ty()))
}

#[no_mangle]
pub extern "C" fn wasmtime_sharedmemory_data(
    mem: &wasmtime_sharedmemory_t,
) -> *const UnsafeCell<u8> {
    mem.data().as_ptr()
}

#[no_mangle]
pub extern "C" fn wasmtime_sharedmemory_data_size(mem: &wasmtime_sharedmemory_t) -> usize {
    mem.data().len()
}

#[no_mangle]
pub extern "C" fn wasmtime_sharedmemory_size(mem: &wasmtime_sharedmemory_t) -> u64 {
    mem.size()
}

#[no_mangle]
pub extern "C" fn wasmtime_sharedmemory_grow(
    mem: &wasmtime_sharedmemory_t,
    delta: u64,
    prev_size: &mut u64,
) -> Option<Box<wasmtime_error_t>> {
    handle_result(mem.grow(delta), |prev| *prev_size = prev)
}
