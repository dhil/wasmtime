;;! target = "aarch64"
;;! test = "compile"
;;! flags = " -C cranelift-enable-heap-access-spectre-mitigation=false -W memory64 -O static-memory-maximum-size=0 -O static-memory-guard-size=0 -O dynamic-memory-guard-size=0"

;; !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
;; !!! GENERATED BY 'make-load-store-tests.sh' DO NOT EDIT !!!
;; !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

(module
  (memory i64 1)

  (func (export "do_store") (param i64 i32)
    local.get 0
    local.get 1
    i32.store8 offset=0xffff0000)

  (func (export "do_load") (param i64) (result i32)
    local.get 0
    i32.load8_u offset=0xffff0000))

;; wasm[0]::function[0]:
;;       stp     x29, x30, [sp, #-0x10]!
;;       mov     x29, sp
;;       mov     w10, #-0xffff
;;       adds    x10, x2, x10
;;       b.hs    #0x3c
;;   14: ldr     x11, [x0, #0x68]
;;       cmp     x10, x11
;;       b.hi    #0x38
;;   20: ldr     x13, [x0, #0x60]
;;       add     x13, x13, x2
;;       mov     x14, #0xffff0000
;;       strb    w3, [x13, x14]
;;       ldp     x29, x30, [sp], #0x10
;;       ret
;;   38: .byte   0x1f, 0xc1, 0x00, 0x00
;;   3c: .byte   0x1f, 0xc1, 0x00, 0x00
;;
;; wasm[0]::function[1]:
;;       stp     x29, x30, [sp, #-0x10]!
;;       mov     x29, sp
;;       mov     w10, #-0xffff
;;       adds    x10, x2, x10
;;       b.hs    #0x7c
;;   54: ldr     x11, [x0, #0x68]
;;       cmp     x10, x11
;;       b.hi    #0x78
;;   60: ldr     x13, [x0, #0x60]
;;       add     x13, x13, x2
;;       mov     x14, #0xffff0000
;;       ldrb    w0, [x13, x14]
;;       ldp     x29, x30, [sp], #0x10
;;       ret
;;   78: .byte   0x1f, 0xc1, 0x00, 0x00
;;   7c: .byte   0x1f, 0xc1, 0x00, 0x00
