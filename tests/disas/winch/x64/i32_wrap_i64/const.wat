;;! target = "x86_64"
;;! test = "winch"

(module
    (func (result i32)
        (i64.const 1)
        (i32.wrap_i64)
    )
)
;; wasm[0]::function[0]:
;;       pushq   %rbp
;;       movq    %rsp, %rbp
;;       movq    8(%rdi), %r11
;;       movq    0x10(%r11), %r11
;;       addq    $0x10, %r11
;;       cmpq    %rsp, %r11
;;       ja      0x3b
;;   1c: movq    %rdi, %r14
;;       subq    $0x10, %rsp
;;       movq    %rdi, 8(%rsp)
;;       movq    %rsi, (%rsp)
;;       movq    $1, %rax
;;       movl    %eax, %eax
;;       addq    $0x10, %rsp
;;       popq    %rbp
;;       retq
;;   3b: ud2
