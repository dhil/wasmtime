;;! target = "aarch64"
;;! test = "compile"
;;! flags = " -C cranelift-enable-heap-access-spectre-mitigation=false -W memory64 -O static-memory-forced -O static-memory-guard-size=4294967295 -O dynamic-memory-guard-size=4294967295"

;; !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
;; !!! GENERATED BY 'make-load-store-tests.sh' DO NOT EDIT !!!
;; !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

(module
  (memory i64 1)

  (func (export "do_store") (param i64 i32)
    local.get 0
    local.get 1
    i32.store offset=0xffff0000)

  (func (export "do_load") (param i64) (result i32)
    local.get 0
    i32.load offset=0xffff0000))

;; wasm[0]::function[0]:
;;       stp     x29, x30, [sp, #-0x10]!
;;       mov     x29, sp
;;       mov     x8, #0xfffc
;;       cmp     x4, x8
;;       cset    x11, hi
;;       uxtb    w10, w11
;;       cbnz    x10, #0x34
;;   1c: ldr     x11, [x2, #0x60]
;;       add     x11, x11, x4
;;       mov     x12, #0xffff0000
;;       str     w5, [x11, x12]
;;       ldp     x29, x30, [sp], #0x10
;;       ret
;;   34: .byte   0x1f, 0xc1, 0x00, 0x00
;;
;; wasm[0]::function[1]:
;;       stp     x29, x30, [sp, #-0x10]!
;;       mov     x29, sp
;;       mov     x8, #0xfffc
;;       cmp     x4, x8
;;       cset    x11, hi
;;       uxtb    w10, w11
;;       cbnz    x10, #0x74
;;   5c: ldr     x11, [x2, #0x60]
;;       add     x11, x11, x4
;;       mov     x12, #0xffff0000
;;       ldr     w2, [x11, x12]
;;       ldp     x29, x30, [sp], #0x10
;;       ret
;;   74: .byte   0x1f, 0xc1, 0x00, 0x00
