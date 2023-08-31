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
;;! [globals.heap_bound]
;;! type = "i64"
;;! load = { base = "vmctx", offset = 8, readonly = true }
;;!
;;! [[heaps]]
;;! base = "heap_base"
;;! min_size = 0x10000
;;! offset_guard_size = 0
;;! index_type = "i32"
;;! style = { kind = "dynamic", bound = "heap_bound" }

;; !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
;; !!! GENERATED BY 'make-load-store-tests.sh' DO NOT EDIT !!!
;; !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

(module
  (memory i32 1)

  (func (export "do_store") (param i32 i32)
    local.get 0
    local.get 1
    i32.store offset=0x1000)

  (func (export "do_load") (param i32) (result i32)
    local.get 0
    i32.load offset=0x1000))

;; function u0:0:
;; block0:
;;   slli t0,a0,32
;;   srli t2,t0,32
;;   ld t1,8(a2)
;;   lui t0,1048575
;;   addi a0,t0,4092
;;   add t1,t1,a0
;;   ugt t1,t2,t1##ty=i64
;;   bne t1,zero,taken(label3),not_taken(label1)
;; block1:
;;   ld a0,0(a2)
;;   add t2,a0,t2
;;   lui a0,1
;;   add t2,t2,a0
;;   sw a1,0(t2)
;;   j label2
;; block2:
;;   ret
;; block3:
;;   udf##trap_code=heap_oob
;;
;; function u0:1:
;; block0:
;;   slli t0,a0,32
;;   srli t2,t0,32
;;   ld t1,8(a1)
;;   lui t0,1048575
;;   addi a0,t0,4092
;;   add t1,t1,a0
;;   ugt t1,t2,t1##ty=i64
;;   bne t1,zero,taken(label3),not_taken(label1)
;; block1:
;;   ld a0,0(a1)
;;   add t2,a0,t2
;;   lui a0,1
;;   add t2,t2,a0
;;   lw a0,0(t2)
;;   j label2
;; block2:
;;   ret
;; block3:
;;   udf##trap_code=heap_oob
