;;! target = "s390x"
;;! test = "compile"
;;! flags = " -C cranelift-enable-heap-access-spectre-mitigation -O static-memory-forced -O static-memory-guard-size=0 -O dynamic-memory-guard-size=0"

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
;;       stmg    %r7, %r15, 0x38(%r15)
;;       lgr     %r1, %r15
;;       aghi    %r15, -0xa0
;;       stg     %r1, 0(%r15)
;;       lgr     %r3, %r2
;;       llgfr   %r2, %r4
;;       lghi    %r4, 0
;;       lgr     %r10, %r3
;;       lgr     %r3, %r2
;;       ag      %r3, 0x60(%r10)
;;       llilh   %r7, 0xffff
;;       agr     %r3, %r7
;;       clgfi   %r2, 0xfffc
;;       locgrh  %r3, %r4
;;       strv    %r5, 0(%r3)
;;       lmg     %r7, %r15, 0xd8(%r15)
;;       br      %r14
;;
;; wasm[0]::function[1]:
;;       stmg    %r14, %r15, 0x70(%r15)
;;       lgr     %r1, %r15
;;       aghi    %r15, -0xa0
;;       stg     %r1, 0(%r15)
;;       llgfr   %r5, %r4
;;       lghi    %r4, 0
;;       lgr     %r3, %r5
;;       ag      %r3, 0x60(%r2)
;;       llilh   %r2, 0xffff
;;       agr     %r3, %r2
;;       clgfi   %r5, 0xfffc
;;       locgrh  %r3, %r4
;;       lrv     %r2, 0(%r3)
;;       lmg     %r14, %r15, 0x110(%r15)
;;       br      %r14
