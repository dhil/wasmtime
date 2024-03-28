;;! target = "x86_64"
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
    i32.store offset=0)

  (func (export "do_load") (param i32) (result i32)
    local.get 0
    i32.load offset=0))

;; wasm[0]::function[0]:
;;       pushq   %rbp
;;       movq    %rsp, %rbp
;;       movq    0x58(%rdi), %r11
;;       movl    %edx, %r10d
;;       cmpq    %r11, %r10
;;       ja      0x21
;;   14: movq    0x50(%rdi), %rsi
;;       movl    %ecx, (%rsi, %r10)
;;       movq    %rbp, %rsp
;;       popq    %rbp
;;       retq
;;   21: ud2
;;
;; wasm[0]::function[1]:
;;       pushq   %rbp
;;       movq    %rsp, %rbp
;;       movq    0x58(%rdi), %r11
;;       movl    %edx, %r10d
;;       cmpq    %r11, %r10
;;       ja      0x51
;;   44: movq    0x50(%rdi), %rsi
;;       movl    (%rsi, %r10), %eax
;;       movq    %rbp, %rsp
;;       popq    %rbp
;;       retq
;;   51: ud2
