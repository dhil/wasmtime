;;! target = "x86_64"
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
    i32.store8 offset=0xffff0000)

  (func (export "do_load") (param i32) (result i32)
    local.get 0
    i32.load8_u offset=0xffff0000))

;; wasm[0]::function[0]:
;;       pushq   %rbp
;;       movq    %rsp, %rbp
;;       movq    0x58(%rdi), %r8
;;       movl    %edx, %edx
;;       xorq    %rax, %rax
;;       movq    %rdx, %r9
;;       addq    0x50(%rdi), %r9
;;       movl    $0xffff0000, %edi
;;       leaq    (%r9, %rdi), %rsi
;;       cmpq    %r8, %rdx
;;       cmovaq  %rax, %rsi
;;       movb    %cl, (%rsi)
;;       movq    %rbp, %rsp
;;       popq    %rbp
;;       retq
;;
;; wasm[0]::function[1]:
;;       pushq   %rbp
;;       movq    %rsp, %rbp
;;       movq    0x58(%rdi), %r9
;;       movl    %edx, %ecx
;;       xorq    %rax, %rax
;;       movq    %rcx, %r8
;;       addq    0x50(%rdi), %r8
;;       movl    $0xffff0000, %edi
;;       leaq    (%r8, %rdi), %rsi
;;       cmpq    %r9, %rcx
;;       cmovaq  %rax, %rsi
;;       movzbq  (%rsi), %rax
;;       movq    %rbp, %rsp
;;       popq    %rbp
;;       retq
