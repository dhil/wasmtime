;;! target = "x86_64"
(module
  (func (export "as-if-else") (result i32)
    (if (result i32) (i32.const 1) (then (i32.const 2)) (else (loop (result i32) (i32.const 1))))
  )
)
;;      	 55                   	push	rbp
;;      	 4889e5               	mov	rbp, rsp
;;      	 4c8b5f08             	mov	r11, qword ptr [rdi + 8]
;;      	 4d8b1b               	mov	r11, qword ptr [r11]
;;      	 4981c310000000       	add	r11, 0x10
;;      	 4939e3               	cmp	r11, rsp
;;      	 0f8732000000         	ja	0x4d
;;   1b:	 4989fe               	mov	r14, rdi
;;      	 4883ec10             	sub	rsp, 0x10
;;      	 48897c2408           	mov	qword ptr [rsp + 8], rdi
;;      	 48893424             	mov	qword ptr [rsp], rsi
;;      	 b801000000           	mov	eax, 1
;;      	 85c0                 	test	eax, eax
;;      	 0f840a000000         	je	0x42
;;   38:	 b802000000           	mov	eax, 2
;;      	 e905000000           	jmp	0x47
;;   42:	 b801000000           	mov	eax, 1
;;      	 4883c410             	add	rsp, 0x10
;;      	 5d                   	pop	rbp
;;      	 c3                   	ret	
;;   4d:	 0f0b                 	ud2	
