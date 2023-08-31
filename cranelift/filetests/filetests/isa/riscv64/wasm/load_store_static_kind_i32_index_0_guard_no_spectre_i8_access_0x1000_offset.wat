;;! target = "riscv64"
;;!
;;! settings = ['enable_heap_access_spectre_mitigation=false']
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
;;   slli t3,a0,32
;;   srli t0,t3,32
;;   lui t3,65535
;;   addi t1,t3,4095
;;   ugt t4,t0,t1##ty=i64
;;   bne t4,zero,taken(label3),not_taken(label1)
;; block1:
;;   ld t1,0(a2)
;;   add t0,t1,t0
;;   lui t1,1
;;   add t0,t0,t1
;;   sb a1,0(t0)
;;   j label2
;; block2:
;;   ret
;; block3:
;;   udf##trap_code=heap_oob
;;
;; function u0:1:
;; block0:
;;   slli t3,a0,32
;;   srli t0,t3,32
;;   lui t3,65535
;;   addi t1,t3,4095
;;   ugt t4,t0,t1##ty=i64
;;   bne t4,zero,taken(label3),not_taken(label1)
;; block1:
;;   ld t1,0(a1)
;;   add t0,t1,t0
;;   lui t1,1
;;   add t0,t0,t1
;;   lbu a0,0(t0)
;;   j label2
;; block2:
;;   ret
;; block3:
;;   udf##trap_code=heap_oob
