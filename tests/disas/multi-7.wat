;;! target = "x86_64"

(module
  (func (export "f") (param i64 i32) (result i64)
    (local.get 0)
    (local.get 1)
    ;; If with no else. Same number of params and results.
    (if (param i64) (result i64)
      (then
        (drop)
        (i64.const -1)))))

;; function u0:0(i64 vmctx, i64, i64, i32) -> i64 fast {
;;     gv0 = vmctx
;;     gv1 = load.i64 notrap aligned readonly gv0+8
;;     gv2 = load.i64 notrap aligned gv1
;;     gv3 = vmctx
;;     sig0 = (i64 vmctx, i32 uext, i32 uext) -> i32 uext system_v
;;     sig1 = (i64 vmctx, i32 uext) -> i32 uext system_v
;;     stack_limit = gv2
;;
;;                                 block0(v0: i64, v1: i64, v2: i64, v3: i32):
;; @0025                               v5 = global_value.i64 gv3
;; @0025                               v6 = load.i64 notrap aligned v5+8
;; @002a                               brif v3, block2, block3(v2)
;;
;;                                 block2:
;; @002d                               v8 = iconst.i64 -1
;; @002f                               jump block3(v8)  ; v8 = -1
;;
;;                                 block3(v7: i64):
;; @0030                               jump block1(v7)
;;
;;                                 block1(v4: i64):
;; @0030                               return v4
;; }
