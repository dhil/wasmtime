;;! target = "aarch64"
;;! test = "compile"
;;! flags = " -C cranelift-enable-heap-access-spectre-mitigation=false -O static-memory-maximum-size=0 -O static-memory-guard-size=0 -O dynamic-memory-guard-size=0"

;; !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
;; !!! GENERATED BY 'make-load-store-tests.sh' DO NOT EDIT !!!
;; !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

(module
  (memory i32 1)

  (func (export "do_store") (param i32 i32)
    local.get 0
    local.get 1
    i32.store offset=0)

  (func (export "do_load") (param i32) (result i32)
    local.get 0
    i32.load offset=0))

;; wasm[0]::function[0]:
;;       stp     x29, x30, [sp, #-0x10]!
;;       mov     x29, sp
;;       ldr     x8, [x0, #0x58]
;;       mov     w9, w2
;;       sub     x8, x8, #4
;;       cmp     x9, x8
;;       b.hi    #0x2c
;;   1c: ldr     x10, [x0, #0x50]
;;       str     w3, [x10, w2, uxtw]
;;       ldp     x29, x30, [sp], #0x10
;;       ret
;;   2c: .byte   0x1f, 0xc1, 0x00, 0x00
;;
;; wasm[0]::function[1]:
;;       stp     x29, x30, [sp, #-0x10]!
;;       mov     x29, sp
;;       ldr     x8, [x0, #0x58]
;;       mov     w9, w2
;;       sub     x8, x8, #4
;;       cmp     x9, x8
;;       b.hi    #0x6c
;;   5c: ldr     x10, [x0, #0x50]
;;       ldr     w0, [x10, w2, uxtw]
;;       ldp     x29, x30, [sp], #0x10
;;       ret
;;   6c: .byte   0x1f, 0xc1, 0x00, 0x00
