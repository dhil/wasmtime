;;! target = "x86_64"

(module
  (func $dummy)
  (func (export "as-func-mid") (result i32)
    (call $dummy) (unreachable) (i32.const -1)
  )
)
;;    0:	 55                   	push	rbp
;;    1:	 4889e5               	mov	rbp, rsp
;;    4:	 4883ec08             	sub	rsp, 8
;;    8:	 4c893424             	mov	qword ptr [rsp], r14
;;    c:	 4883c408             	add	rsp, 8
;;   10:	 5d                   	pop	rbp
;;   11:	 c3                   	ret	
;;
;;    0:	 55                   	push	rbp
;;    1:	 4889e5               	mov	rbp, rsp
;;    4:	 4883ec08             	sub	rsp, 8
;;    8:	 4c893424             	mov	qword ptr [rsp], r14
;;    c:	 4883ec08             	sub	rsp, 8
;;   10:	 e800000000           	call	0x15
;;   15:	 4883c408             	add	rsp, 8
;;   19:	 0f0b                 	ud2	
;;   1b:	 4883c408             	add	rsp, 8
;;   1f:	 5d                   	pop	rbp
;;   20:	 c3                   	ret	
