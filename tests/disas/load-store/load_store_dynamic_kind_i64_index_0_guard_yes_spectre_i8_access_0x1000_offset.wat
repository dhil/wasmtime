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
    i32.store8 offset=0x1000)

  (func (export "do_load") (param i64) (result i32)
    local.get 0
    i32.load8_u offset=0x1000))

;; function u0:0(i64 vmctx, i64, i64, i32) tail {
;;     gv0 = vmctx
;;     gv1 = load.i64 notrap aligned readonly gv0+8
;;     gv2 = load.i64 notrap aligned gv1+16
;;     gv3 = vmctx
;;     gv4 = load.i64 notrap aligned gv3+104
;;     gv5 = load.i64 notrap aligned checked gv3+96
;;     stack_limit = gv2
;;
;;                                 block0(v0: i64, v1: i64, v2: i64, v3: i32):
;; @0040                               v4 = global_value.i64 gv4
;; @0040                               v5 = iconst.i64 4097
;; @0040                               v6 = isub v4, v5  ; v5 = 4097
;; @0040                               v7 = icmp ugt v2, v6
;; @0040                               v8 = global_value.i64 gv5
;; @0040                               v9 = iadd v8, v2
;; @0040                               v10 = iconst.i64 4096
;; @0040                               v11 = iadd v9, v10  ; v10 = 4096
;; @0040                               v12 = iconst.i64 0
;; @0040                               v13 = select_spectre_guard v7, v12, v11  ; v12 = 0
;; @0040                               istore8 little heap v3, v13
;; @0044                               jump block1
;;
;;                                 block1:
;; @0044                               return
;; }
;;
;; function u0:1(i64 vmctx, i64, i64) -> i32 tail {
;;     gv0 = vmctx
;;     gv1 = load.i64 notrap aligned readonly gv0+8
;;     gv2 = load.i64 notrap aligned gv1+16
;;     gv3 = vmctx
;;     gv4 = load.i64 notrap aligned gv3+104
;;     gv5 = load.i64 notrap aligned checked gv3+96
;;     stack_limit = gv2
;;
;;                                 block0(v0: i64, v1: i64, v2: i64):
;; @0049                               v4 = global_value.i64 gv4
;; @0049                               v5 = iconst.i64 4097
;; @0049                               v6 = isub v4, v5  ; v5 = 4097
;; @0049                               v7 = icmp ugt v2, v6
;; @0049                               v8 = global_value.i64 gv5
;; @0049                               v9 = iadd v8, v2
;; @0049                               v10 = iconst.i64 4096
;; @0049                               v11 = iadd v9, v10  ; v10 = 4096
;; @0049                               v12 = iconst.i64 0
;; @0049                               v13 = select_spectre_guard v7, v12, v11  ; v12 = 0
;; @0049                               v14 = uload8.i32 little heap v13
;; @004d                               jump block1(v14)
;;
;;                                 block1(v3: i32):
;; @004d                               return v3
;; }
