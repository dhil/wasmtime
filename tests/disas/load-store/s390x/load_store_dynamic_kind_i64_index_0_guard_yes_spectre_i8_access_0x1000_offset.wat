;;! target = "s390x"
;;! test = "compile"
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

;; wasm[0]::function[0]:
;;       stmg    %r7, %r15, 0x38(%r15)
;;       lgr     %r1, %r15
;;       aghi    %r15, -0xa0
;;       stg     %r1, 0(%r15)
;;       lg      %r3, 0x58(%r2)
;;       aghik   %r7, %r3, -0x1001
;;       lghi    %r3, 0
;;       lgr     %r8, %r4
;;       ag      %r8, 0x50(%r2)
;;       aghik   %r2, %r8, 0x1000
;;       clgr    %r4, %r7
;;       locgrh  %r2, %r3
;;       stc     %r5, 0(%r2)
;;       lmg     %r7, %r15, 0xd8(%r15)
;;       br      %r14
;;
;; wasm[0]::function[1]:
;;       stmg    %r7, %r15, 0x38(%r15)
;;       lgr     %r1, %r15
;;       aghi    %r15, -0xa0
;;       stg     %r1, 0(%r15)
;;       lg      %r5, 0x58(%r2)
;;       aghik   %r3, %r5, -0x1001
;;       lghi    %r5, 0
;;       lgr     %r7, %r4
;;       ag      %r7, 0x50(%r2)
;;       aghik   %r2, %r7, 0x1000
;;       clgr    %r4, %r3
;;       locgrh  %r2, %r5
;;       llc     %r2, 0(%r2)
;;       lmg     %r7, %r15, 0xd8(%r15)
;;       br      %r14
