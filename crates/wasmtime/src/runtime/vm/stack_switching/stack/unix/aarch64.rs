// A WORD OF CAUTION
//
// This entire file basically needs to be kept in sync with itself and with the
// control-context layout in Cranelift's AArch64 `stack_switch` implementation.
// Read all of it before changing any individual part.

use core::arch::naked_asm;

#[inline(never)] // FIXME(rust-lang/rust#148307)
pub fn wasmtime_continuation_start_address() -> *const () {
    wasmtime_continuation_start as *const ()
}

// This function is never called directly. A `stack_switch` enters it after
// loading a freshly initialized continuation's control context. At entry:
//
//   SP: TOS - 0x40 - (16 * `args_capacity`)
//   FP: TOS - 0x10
//
// The four words at SP contain, in order, `return_value_count`, `args`,
// `caller_vmctx`, and `func_ref`. FP points at a synthetic AAPCS64 frame record:
// the parent FP is at [FP], the parent PC at [FP + 8], and the parent SP at
// [FP - 8]. The first stack switch fills in those parent-context values.
#[unsafe(naked)]
pub(crate) unsafe extern "C" fn wasmtime_continuation_start() {
    naked_asm!(
        "
        // This is an indirect-call-compatible landing pad. `bti` is a hint on
        // processors where branch target identification is not enabled.
        bti c

        // Call fiber_start(func_ref, caller_vmctx, args, return_value_count).
        ldp x3, x2, [sp]
        ldp x1, x0, [sp, #16]
        add sp, sp, #32
        bl {fiber_start}

        // A failed array call means that the continuation trapped. Preserve
        // this information as the control effect sent to the parent stack.
        cbz w0, 2f
        mov x0, xzr
        b 3f
    2:
        mov x0, {trap_control_effect}
    3:

        // FP is callee-saved, so it still points at the synthetic frame record.
        // Restore all three parent-context values before replacing FP.
        ldur x17, [x29, #-8]
        ldp x29, x16, [x29]
        mov sp, x17
        br x16
        ",
        fiber_start = sym super::fiber_start,
        trap_control_effect = const crate::vm::CONTROL_EFFECT_TRAP_ENCODING,
    );
}

#[test]
fn test_control_effect_payloads() {
    // This assumption is baked into `wasmtime_continuation_start`.
    assert_eq!(wasmtime_environ::CONTROL_EFFECT_RETURN_DISCRIMINANT, 0);
}
