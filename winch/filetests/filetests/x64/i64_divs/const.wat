;;! target = "x86_64"

(module
    (func (result i64)
	(i64.const 20)
	(i64.const 10)
	(i64.div_s)
    )
)
;;    0:	 55                   	push	rbp
;;    1:	 4889e5               	mov	rbp, rsp
;;    4:	 4883ec08             	sub	rsp, 8
;;    8:	 4c893424             	mov	qword ptr [rsp], r14
;;    c:	 48c7c10a000000       	mov	rcx, 0xa
;;   13:	 48c7c014000000       	mov	rax, 0x14
;;   1a:	 4883f900             	cmp	rcx, 0
;;   1e:	 0f840b000000         	je	0x2f
;;   24:	 4899                 	cqo	
;;   26:	 48f7f9               	idiv	rcx
;;   29:	 4883c408             	add	rsp, 8
;;   2d:	 5d                   	pop	rbp
;;   2e:	 c3                   	ret	
;;   2f:	 0f0b                 	ud2	
