;;! target = "x86_64"
;;! test = "compile"
;;! flags = " -C cranelift-enable-heap-access-spectre-mitigation=false -W memory64 -O static-memory-maximum-size=0 -O static-memory-guard-size=4294967295 -O dynamic-memory-guard-size=4294967295"

;; !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
;; !!! GENERATED BY 'make-load-store-tests.sh' DO NOT EDIT !!!
;; !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

(module
  (memory i64 1)

  (func (export "do_store") (param i64 i32)
    local.get 0
    local.get 1
    i32.store offset=0)

  (func (export "do_load") (param i64) (result i32)
    local.get 0
    i32.load offset=0))

;; wasm[0]::function[0]:
;;       pushq   %rbp
;;       movq    %rsp, %rbp
;;       cmpq    0x68(%rdi), %rdx
;;       seta    %r9b
;;       testb   %r9b, %r9b
;;       jne     0x22
;;   15: movq    0x60(%rdi), %r11
;;       movl    %ecx, (%r11, %rdx)
;;       movq    %rbp, %rsp
;;       popq    %rbp
;;       retq
;;   22: ud2
;;
;; wasm[0]::function[1]:
;;       pushq   %rbp
;;       movq    %rsp, %rbp
;;       cmpq    0x68(%rdi), %rdx
;;       seta    %r9b
;;       testb   %r9b, %r9b
;;       jne     0x62
;;   55: movq    0x60(%rdi), %r11
;;       movl    (%r11, %rdx), %eax
;;       movq    %rbp, %rsp
;;       popq    %rbp
;;       retq
;;   62: ud2
