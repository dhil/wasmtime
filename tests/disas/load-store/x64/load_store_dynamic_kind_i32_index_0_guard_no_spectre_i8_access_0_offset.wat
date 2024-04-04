;;! target = "x86_64"
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
    i32.store8 offset=0)

  (func (export "do_load") (param i32) (result i32)
    local.get 0
    i32.load8_u offset=0))

;; wasm[0]::function[0]:
;;       pushq   %rbp
;;       movq    %rsp, %rbp
;;       movq    0x68(%rdi), %r11
;;       movl    %edx, %r10d
;;       cmpq    %r11, %r10
;;       jae     0x21
;;   14: movq    0x60(%rdi), %rsi
;;       movb    %cl, (%rsi, %r10)
;;       movq    %rbp, %rsp
;;       popq    %rbp
;;       retq
;;   21: ud2
;;
;; wasm[0]::function[1]:
;;       pushq   %rbp
;;       movq    %rsp, %rbp
;;       movq    0x68(%rdi), %r11
;;       movl    %edx, %r10d
;;       cmpq    %r11, %r10
;;       jae     0x52
;;   44: movq    0x60(%rdi), %rsi
;;       movzbq  (%rsi, %r10), %rax
;;       movq    %rbp, %rsp
;;       popq    %rbp
;;       retq
;;   52: ud2
