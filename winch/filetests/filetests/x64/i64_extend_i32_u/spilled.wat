;;! target = "x86_64"

(module
    (func (result i64)
        i32.const 1
        i64.extend_i32_u
        block
        end
    )
)
;;      	 55                   	push	rbp
;;      	 4889e5               	mov	rbp, rsp
;;      	 4c8b5f08             	mov	r11, qword ptr [rdi + 8]
;;      	 4d8b1b               	mov	r11, qword ptr [r11]
;;      	 4981c318000000       	add	r11, 0x18
;;      	 4939e3               	cmp	r11, rsp
;;      	 0f871f000000         	ja	0x3a
;;   1b:	 4989fe               	mov	r14, rdi
;;      	 4883ec10             	sub	rsp, 0x10
;;      	 48897c2408           	mov	qword ptr [rsp + 8], rdi
;;      	 48893424             	mov	qword ptr [rsp], rsi
;;      	 b801000000           	mov	eax, 1
;;      	 8bc0                 	mov	eax, eax
;;      	 50                   	push	rax
;;      	 58                   	pop	rax
;;      	 4883c410             	add	rsp, 0x10
;;      	 5d                   	pop	rbp
;;      	 c3                   	ret	
;;   3a:	 0f0b                 	ud2	
