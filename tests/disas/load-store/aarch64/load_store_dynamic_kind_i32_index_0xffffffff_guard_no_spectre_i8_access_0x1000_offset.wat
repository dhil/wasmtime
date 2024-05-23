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
    i32.store8 offset=0x1000)

  (func (export "do_load") (param i32) (result i32)
    local.get 0
    i32.load8_u offset=0x1000))

;; wasm[0]::function[0]:
;;       stp     x29, x30, [sp, #-0x10]!
;;       mov     x29, sp
;;       ldr     x7, [x2, #0x68]
;;       mov     w8, w4
;;       cmp     x8, x7
;;       b.hi    #0x2c
;;   18: ldr     x9, [x2, #0x60]
;;       add     x9, x9, #1, lsl #12
;;       strb    w5, [x9, w4, uxtw]
;;       ldp     x29, x30, [sp], #0x10
;;       ret
;;   2c: .byte   0x1f, 0xc1, 0x00, 0x00
;;
;; wasm[0]::function[1]:
;;       stp     x29, x30, [sp, #-0x10]!
;;       mov     x29, sp
;;       ldr     x7, [x2, #0x68]
;;       mov     w8, w4
;;       cmp     x8, x7
;;       b.hi    #0x6c
;;   58: ldr     x9, [x2, #0x60]
;;       add     x8, x9, #1, lsl #12
;;       ldrb    w2, [x8, w4, uxtw]
;;       ldp     x29, x30, [sp], #0x10
;;       ret
;;   6c: .byte   0x1f, 0xc1, 0x00, 0x00
