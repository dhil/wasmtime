;;! target = "x86_64"

(module
  (func $dummy)
  (func (export "singular") (param i32) (result i32)
    (if (local.get 0) (then (nop)))
    (if (local.get 0) (then (nop)) (else (nop)))
    (if (result i32) (local.get 0) (then (i32.const 7)) (else (i32.const 8)))
  )
)
;;      	 55                   	push	rbp
;;      	 4889e5               	mov	rbp, rsp
;;      	 4c8b5f08             	mov	r11, qword ptr [rdi + 8]
;;      	 4d8b1b               	mov	r11, qword ptr [r11]
;;      	 4981c310000000       	add	r11, 0x10
;;      	 4939e3               	cmp	r11, rsp
;;      	 0f8716000000         	ja	0x31
;;   1b:	 4989fe               	mov	r14, rdi
;;      	 4883ec10             	sub	rsp, 0x10
;;      	 48897c2408           	mov	qword ptr [rsp + 8], rdi
;;      	 48893424             	mov	qword ptr [rsp], rsi
;;      	 4883c410             	add	rsp, 0x10
;;      	 5d                   	pop	rbp
;;      	 c3                   	ret	
;;   31:	 0f0b                 	ud2	
;;
;;      	 55                   	push	rbp
;;      	 4889e5               	mov	rbp, rsp
;;      	 4c8b5f08             	mov	r11, qword ptr [rdi + 8]
;;      	 4d8b1b               	mov	r11, qword ptr [r11]
;;      	 4981c318000000       	add	r11, 0x18
;;      	 4939e3               	cmp	r11, rsp
;;      	 0f874e000000         	ja	0x69
;;   1b:	 4989fe               	mov	r14, rdi
;;      	 4883ec18             	sub	rsp, 0x18
;;      	 48897c2410           	mov	qword ptr [rsp + 0x10], rdi
;;      	 4889742408           	mov	qword ptr [rsp + 8], rsi
;;      	 89542404             	mov	dword ptr [rsp + 4], edx
;;      	 8b442404             	mov	eax, dword ptr [rsp + 4]
;;      	 85c0                 	test	eax, eax
;;      	 0f8400000000         	je	0x3c
;;   3c:	 8b442404             	mov	eax, dword ptr [rsp + 4]
;;      	 85c0                 	test	eax, eax
;;      	 0f8400000000         	je	0x48
;;   48:	 8b442404             	mov	eax, dword ptr [rsp + 4]
;;      	 85c0                 	test	eax, eax
;;      	 0f840a000000         	je	0x5e
;;   54:	 b807000000           	mov	eax, 7
;;      	 e905000000           	jmp	0x63
;;   5e:	 b808000000           	mov	eax, 8
;;      	 4883c418             	add	rsp, 0x18
;;      	 5d                   	pop	rbp
;;      	 c3                   	ret	
;;   69:	 0f0b                 	ud2	
