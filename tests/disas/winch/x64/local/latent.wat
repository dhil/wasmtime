;;! target = "x86_64"
;;! test = "winch"

(module
  (func (export "") (param i32) (result i32)
    local.get 0
    i32.const 1
    local.set 0
  )
)
;; wasm[0]::function[0]:
;;       pushq   %rbp
;;       movq    %rsp, %rbp
;;       movq    8(%rdi), %r11
;;       movq    (%r11), %r11
;;       addq    $0x1c, %r11
;;       cmpq    %rsp, %r11
;;       ja      0x53
;;   1b: movq    %rdi, %r14
;;       subq    $0x18, %rsp
;;       movq    %rdi, 0x10(%rsp)
;;       movq    %rsi, 8(%rsp)
;;       movl    %edx, 4(%rsp)
;;       movl    4(%rsp), %r11d
;;       subq    $4, %rsp
;;       movl    %r11d, (%rsp)
;;       movl    $1, %eax
;;       movl    %eax, 8(%rsp)
;;       movl    (%rsp), %eax
;;       addq    $4, %rsp
;;       addq    $0x18, %rsp
;;       popq    %rbp
;;       retq
;;   53: ud2
