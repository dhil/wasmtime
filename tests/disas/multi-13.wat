;;! target = "x86_64"

(module
  (func (export "as-if-then") (param i32 i32) (result i32)
    (block (result i32)
      (if (result i32) (local.get 0)
        (then (br 1 (i32.const 3)))
        (else (local.get 1))
      )
    )
  )
)

;; function u0:0(i64 vmctx, i64, i32, i32) -> i32 fast {
;;     gv0 = vmctx
;;     gv1 = load.i64 notrap aligned readonly gv0+8
;;     gv2 = load.i64 notrap aligned gv1
;;     gv3 = vmctx
;;     sig0 = (i64 vmctx, i32 uext, i32 uext) -> i32 uext system_v
;;     sig1 = (i64 vmctx, i32 uext) -> i32 uext system_v
;;     stack_limit = gv2
;;
;;                                 block0(v0: i64, v1: i64, v2: i32, v3: i32):
;; @0029                               v5 = global_value.i64 gv3
;; @0029                               v6 = load.i64 notrap aligned v5+8
;; @002e                               brif v2, block3, block5
;;
;;                                 block3:
;; @0030                               v9 = iconst.i32 3
;; @0032                               jump block2(v9)  ; v9 = 3
;;
;;                                 block5:
;; @0037                               jump block4(v3)
;;
;;                                 block4(v8: i32):
;; @0038                               jump block2(v8)
;;
;;                                 block2(v7: i32):
;; @0039                               jump block1(v7)
;;
;;                                 block1(v4: i32):
;; @0039                               return v4
;; }
