;;! target = "riscv64"
;;!
;;! settings = ['enable_heap_access_spectre_mitigation=true']
;;!
;;! compile = true
;;!
;;! [globals.vmctx]
;;! type = "i64"
;;! vmctx = true
;;!
;;! [globals.heap_base]
;;! type = "i64"
;;! load = { base = "vmctx", offset = 0, readonly = true }
;;!
;;! # (no heap_bound global for static heaps)
;;!
;;! [[heaps]]
;;! base = "heap_base"
;;! min_size = 0x10000
;;! offset_guard_size = 0
;;! index_type = "i32"
;;! style = { kind = "static", bound = 0x10000000 }

;; !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
;; !!! GENERATED BY 'make-load-store-tests.sh' DO NOT EDIT !!!
;; !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

(module
  (memory i32 1)

  (func (export "do_store") (param i32 i32)
    local.get 0
    local.get 1
    i32.store8 offset=0x1000)

  (func (export "do_load") (param i32) (result i32)
    local.get 0
    i32.load8_u offset=0x1000))

;; function u0:0:
;; block0:
;;   mv a4,a2
;;   slli a0,a0,32
;;   srli a3,a0,32
;;   lui a0,65535
;;   addi a2,a0,-1
;;   ugt a2,a3,a2##ty=i64
;;   ld a4,0(a4)
;;   add a3,a4,a3
;;   lui a4,1
;;   add a3,a3,a4
;;   li a4,0
;;   sltu a2,zero,a2
;;   sub a5,zero,a2
;;   and a0,a4,a5
;;   not a2,a5
;;   and a4,a3,a2
;;   or a0,a0,a4
;;   sb a1,0(a0)
;;   j label1
;; block1:
;;   ret
;;
;; function u0:1:
;; block0:
;;   mv a4,a1
;;   slli a0,a0,32
;;   srli a2,a0,32
;;   lui a0,65535
;;   addi a3,a0,-1
;;   ugt a1,a2,a3##ty=i64
;;   mv a3,a4
;;   ld a3,0(a3)
;;   add a2,a3,a2
;;   lui a3,1
;;   add a2,a2,a3
;;   li a3,0
;;   sltu a4,zero,a1
;;   sub a4,zero,a4
;;   and a0,a3,a4
;;   not a3,a4
;;   and a4,a2,a3
;;   or a0,a0,a4
;;   lbu a0,0(a0)
;;   j label1
;; block1:
;;   ret
