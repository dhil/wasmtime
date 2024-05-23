;;! target = "x86_64"
;;! test = "clif"
;;! flags = " -C cranelift-enable-heap-access-spectre-mitigation -W memory64 -O static-memory-maximum-size=0 -O static-memory-guard-size=0 -O dynamic-memory-guard-size=0"

;; !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
;; !!! GENERATED BY 'make-load-store-tests.sh' DO NOT EDIT !!!
;; !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

(module
  (memory i64 1)

  (func (export "do_store") (param i64 i32)
    local.get 0
    local.get 1
    i32.store8 offset=0xffff0000)

  (func (export "do_load") (param i64) (result i32)
    local.get 0
    i32.load8_u offset=0xffff0000))

;; function u0:0(i64 vmctx, i64, i64, i32) tail {
;;     gv0 = vmctx
;;     gv1 = load.i64 notrap aligned readonly gv0+8
;;     gv2 = load.i64 notrap aligned gv1
;;     gv3 = vmctx
;;     gv4 = load.i64 notrap aligned gv3+104
;;     gv5 = load.i64 notrap aligned checked gv3+96
;;     stack_limit = gv2
;;
;;                                 block0(v0: i64, v1: i64, v2: i64, v3: i32):
;; @0040                               v4 = iconst.i64 0xffff_0001
;; @0040                               v5 = uadd_overflow_trap v2, v4, heap_oob  ; v4 = 0xffff_0001
;; @0040                               v6 = global_value.i64 gv4
;; @0040                               v7 = icmp ugt v5, v6
;; @0040                               v8 = global_value.i64 gv5
;; @0040                               v9 = iadd v8, v2
;; @0040                               v10 = iconst.i64 0xffff_0000
;; @0040                               v11 = iadd v9, v10  ; v10 = 0xffff_0000
;; @0040                               v12 = iconst.i64 0
;; @0040                               v13 = select_spectre_guard v7, v12, v11  ; v12 = 0
;; @0040                               istore8 little heap v3, v13
;; @0047                               jump block1
;;
;;                                 block1:
;; @0047                               return
;; }
;;
;; function u0:1(i64 vmctx, i64, i64) -> i32 tail {
;;     gv0 = vmctx
;;     gv1 = load.i64 notrap aligned readonly gv0+8
;;     gv2 = load.i64 notrap aligned gv1
;;     gv3 = vmctx
;;     gv4 = load.i64 notrap aligned gv3+104
;;     gv5 = load.i64 notrap aligned checked gv3+96
;;     stack_limit = gv2
;;
;;                                 block0(v0: i64, v1: i64, v2: i64):
;; @004c                               v4 = iconst.i64 0xffff_0001
;; @004c                               v5 = uadd_overflow_trap v2, v4, heap_oob  ; v4 = 0xffff_0001
;; @004c                               v6 = global_value.i64 gv4
;; @004c                               v7 = icmp ugt v5, v6
;; @004c                               v8 = global_value.i64 gv5
;; @004c                               v9 = iadd v8, v2
;; @004c                               v10 = iconst.i64 0xffff_0000
;; @004c                               v11 = iadd v9, v10  ; v10 = 0xffff_0000
;; @004c                               v12 = iconst.i64 0
;; @004c                               v13 = select_spectre_guard v7, v12, v11  ; v12 = 0
;; @004c                               v14 = uload8.i32 little heap v13
;; @0053                               jump block1(v14)
;;
;;                                 block1(v3: i32):
;; @0053                               return v3
;; }
