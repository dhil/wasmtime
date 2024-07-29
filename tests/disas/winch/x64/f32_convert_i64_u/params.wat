;;! target = "x86_64"
;;! test = "winch"

(module
    (func (param i64) (result f32)
        (local.get 0)
        (f32.convert_i64_u)
    )
)
;; wasm[0]::function[0]:
;;       pushq   %rbp
;;       movq    %rsp, %rbp
;;       movq    8(%rdi), %r11
;;       movq    (%r11), %r11
;;       addq    $0x20, %r11
;;       cmpq    %rsp, %r11
;;       ja      0x6a
;;   1b: movq    %rdi, %r14
;;       subq    $0x20, %rsp
;;       movq    %rdi, 0x18(%rsp)
;;       movq    %rsi, 0x10(%rsp)
;;       movq    %rdx, 8(%rsp)
;;       movq    8(%rsp), %rcx
;;       cmpq    $0, %rcx
;;       jl      0x4a
;;   40: cvtsi2ssq %rcx, %xmm0
;;       jmp     0x64
;;   4a: movq    %rcx, %r11
;;       shrq    $1, %r11
;;       movq    %rcx, %rax
;;       andq    $1, %rax
;;       orq     %r11, %rax
;;       cvtsi2ssq %rax, %xmm0
;;       addss   %xmm0, %xmm0
;;       addq    $0x20, %rsp
;;       popq    %rbp
;;       retq
;;   6a: ud2
