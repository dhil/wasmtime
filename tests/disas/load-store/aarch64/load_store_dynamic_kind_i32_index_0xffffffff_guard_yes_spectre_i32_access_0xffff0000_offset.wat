;;! target = "aarch64"
;;! test = "compile"
;;! flags = " -C cranelift-enable-heap-access-spectre-mitigation -O static-memory-maximum-size=0 -O static-memory-guard-size=4294967295 -O dynamic-memory-guard-size=4294967295"

;; !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
;; !!! GENERATED BY 'make-load-store-tests.sh' DO NOT EDIT !!!
;; !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

(module
  (memory i32 1)

  (func (export "do_store") (param i32 i32)
    local.get 0
    local.get 1
    i32.store offset=0xffff0000)

  (func (export "do_load") (param i32) (result i32)
    local.get 0
    i32.load offset=0xffff0000))

;; wasm[0]::function[0]:
;;       stp     x29, x30, [sp, #-0x10]!
;;       mov     x29, sp
;;       ldr     x12, [x0, #0x68]
;;       ldr     x15, [x0, #0x60]
;;       mov     w13, w2
;;       mov     x14, #0
;;       add     x15, x15, w2, uxtw
;;       mov     x0, #0xffff0000
;;       add     x15, x15, x0
;;       cmp     x13, x12
;;       csel    x13, x14, x15, hi
;;       csdb
;;       str     w3, [x13]
;;       ldp     x29, x30, [sp], #0x10
;;       ret
;;
;; wasm[0]::function[1]:
;;       stp     x29, x30, [sp, #-0x10]!
;;       mov     x29, sp
;;       ldr     x12, [x0, #0x68]
;;       ldr     x15, [x0, #0x60]
;;       mov     w13, w2
;;       mov     x14, #0
;;       add     x15, x15, w2, uxtw
;;       mov     x0, #0xffff0000
;;       add     x15, x15, x0
;;       cmp     x13, x12
;;       csel    x13, x14, x15, hi
;;       csdb
;;       ldr     w0, [x13]
;;       ldp     x29, x30, [sp], #0x10
;;       ret
