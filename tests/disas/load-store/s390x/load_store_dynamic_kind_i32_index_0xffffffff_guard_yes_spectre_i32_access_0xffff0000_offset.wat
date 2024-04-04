;;! target = "s390x"
;;! test = "compile"
;;! flags = " -C cranelift-enable-heap-access-spectre-mitigation -O static-memory-maximum-size=0 -O static-memory-guard-size=4294967295 -O dynamic-memory-guard-size=4294967295"

;; !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
;; !!! GENERATED BY 'make-load-store-tests.sh' DO NOT EDIT !!!
;; !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

(module
  (memory i32 1)

  (func (export "do_store") (param i32 i32)
    local.get 0
    local.get 1
    i32.store offset=0xffff0000)

  (func (export "do_load") (param i32) (result i32)
    local.get 0
    i32.load offset=0xffff0000))

;; wasm[0]::function[0]:
;;       stmg    %r8, %r15, 0x40(%r15)
;;       lgr     %r1, %r15
;;       aghi    %r15, -0xa0
;;       stg     %r1, 0(%r15)
;;       lg      %r8, 0x68(%r2)
;;       llgfr   %r4, %r4
;;       lghi    %r3, 0
;;       lgr     %r9, %r4
;;       ag      %r9, 0x60(%r2)
;;       llilh   %r2, 0xffff
;;       agrk    %r2, %r9, %r2
;;       clgr    %r4, %r8
;;       locgrh  %r2, %r3
;;       strv    %r5, 0(%r2)
;;       lmg     %r8, %r15, 0xe0(%r15)
;;       br      %r14
;;
;; wasm[0]::function[1]:
;;       stmg    %r8, %r15, 0x40(%r15)
;;       lgr     %r1, %r15
;;       aghi    %r15, -0xa0
;;       stg     %r1, 0(%r15)
;;       lg      %r5, 0x68(%r2)
;;       llgfr   %r3, %r4
;;       lghi    %r4, 0
;;       lgr     %r8, %r3
;;       ag      %r8, 0x60(%r2)
;;       llilh   %r2, 0xffff
;;       agrk    %r2, %r8, %r2
;;       clgr    %r3, %r5
;;       locgrh  %r2, %r4
;;       lrv     %r2, 0(%r2)
;;       lmg     %r8, %r15, 0xe0(%r15)
;;       br      %r14
