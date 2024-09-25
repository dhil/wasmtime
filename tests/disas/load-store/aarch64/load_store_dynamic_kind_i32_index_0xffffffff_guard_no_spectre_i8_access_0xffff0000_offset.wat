;;! target = "aarch64"
;;! test = "compile"
;;! flags = " -C cranelift-enable-heap-access-spectre-mitigation=false -O static-memory-maximum-size=0 -O static-memory-guard-size=4294967295 -O dynamic-memory-guard-size=4294967295"

;; !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
;; !!! GENERATED BY 'make-load-store-tests.sh' DO NOT EDIT !!!
;; !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

(module
  (memory i32 1)

  (func (export "do_store") (param i32 i32)
    local.get 0
    local.get 1
    i32.store8 offset=0xffff0000)

  (func (export "do_load") (param i32) (result i32)
    local.get 0
    i32.load8_u offset=0xffff0000))

;; wasm[0]::function[0]:
;;       stp     x29, x30, [sp, #-0x10]!
;;       mov     x29, sp
;;       ldr     x10, [x2, #0x68]
;;       mov     w11, w4
;;       cmp     x11, x10
;;       cset    x11, hi
;;       uxtb    w11, w11
;;       cbnz    x11, #0x38
;;   20: ldr     x12, [x2, #0x60]
;;       add     x12, x12, w4, uxtw
;;       mov     x13, #0xffff0000
;;       strb    w5, [x12, x13]
;;       ldp     x29, x30, [sp], #0x10
;;       ret
;;   38: .byte   0x1f, 0xc1, 0x00, 0x00
;;
;; wasm[0]::function[1]:
;;       stp     x29, x30, [sp, #-0x10]!
;;       mov     x29, sp
;;       ldr     x10, [x2, #0x68]
;;       mov     w11, w4
;;       cmp     x11, x10
;;       cset    x11, hi
;;       uxtb    w11, w11
;;       cbnz    x11, #0x78
;;   60: ldr     x12, [x2, #0x60]
;;       add     x12, x12, w4, uxtw
;;       mov     x13, #0xffff0000
;;       ldrb    w2, [x12, x13]
;;       ldp     x29, x30, [sp], #0x10
;;       ret
;;   78: .byte   0x1f, 0xc1, 0x00, 0x00
