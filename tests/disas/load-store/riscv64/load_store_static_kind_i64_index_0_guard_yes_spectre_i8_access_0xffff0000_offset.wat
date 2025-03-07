;;! target = "riscv64"
;;! test = "compile"
;;! flags = " -C cranelift-enable-heap-access-spectre-mitigation -W memory64 -O static-memory-forced -O static-memory-guard-size=0 -O dynamic-memory-guard-size=0"

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

;; wasm[0]::function[0]:
;;       addi    sp, sp, -0x10
;;       sd      ra, 8(sp)
;;       sd      s0, 0(sp)
;;       mv      s0, sp
;;       lui     a1, 0x10
;;       addi    a4, a1, -1
;;       sltu    a4, a4, a2
;;       ld      a5, 0x50(a0)
;;       add     a2, a5, a2
;;       lui     a1, 0xffff
;;       slli    a5, a1, 4
;;       add     a2, a2, a5
;;       neg     a0, a4
;;       not     a4, a0
;;       and     a4, a2, a4
;;       sb      a3, 0(a4)
;;       ld      ra, 8(sp)
;;       ld      s0, 0(sp)
;;       addi    sp, sp, 0x10
;;       ret
;;
;; wasm[0]::function[1]:
;;       addi    sp, sp, -0x10
;;       sd      ra, 8(sp)
;;       sd      s0, 0(sp)
;;       mv      s0, sp
;;       lui     a1, 0x10
;;       addi    a3, a1, -1
;;       sltu    a3, a3, a2
;;       ld      a4, 0x50(a0)
;;       add     a2, a4, a2
;;       lui     a1, 0xffff
;;       slli    a4, a1, 4
;;       add     a2, a2, a4
;;       neg     a0, a3
;;       not     a3, a0
;;       and     a4, a2, a3
;;       lbu     a0, 0(a4)
;;       ld      ra, 8(sp)
;;       ld      s0, 0(sp)
;;       addi    sp, sp, 0x10
;;       ret
