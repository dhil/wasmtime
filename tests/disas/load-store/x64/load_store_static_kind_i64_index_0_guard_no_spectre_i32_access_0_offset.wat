;;! target = "x86_64"
;;! test = "compile"
;;! flags = " -C cranelift-enable-heap-access-spectre-mitigation=false -W memory64 -O static-memory-forced -O static-memory-guard-size=0 -O dynamic-memory-guard-size=0"

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
;;       cmpq    0x15(%rip), %rdx
;;       ja      0x1e
;;   11: movq    0x60(%rdi), %r9
;;       movl    %ecx, (%r9, %rdx)
;;       movq    %rbp, %rsp
;;       popq    %rbp
;;       retq
;;   1e: ud2
;;   20: cld
;;
;; wasm[0]::function[1]:
;;       pushq   %rbp
;;       movq    %rsp, %rbp
;;       cmpq    0x15(%rip), %rdx
;;       ja      0x5e
;;   51: movq    0x60(%rdi), %r9
;;       movl    (%r9, %rdx), %eax
;;       movq    %rbp, %rsp
;;       popq    %rbp
;;       retq
;;   5e: ud2
;;   60: cld
