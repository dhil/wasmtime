;;! target = "riscv64"
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
;;       addi    sp, sp, -0x10
;;       sd      ra, 8(sp)
;;       sd      s0, 0(sp)
;;       mv      s0, sp
;;       slli    a4, a2, 0x20
;;       srli    a1, a4, 0x20
;;       lui     a4, 0x10
;;       addi    a2, a4, -4
;;       sltu    a5, a2, a1
;;       ld      a0, 0x50(a0)
;;       add     a0, a0, a1
;;       lui     a4, 0xffff
;;       slli    a1, a4, 4
;;       add     a0, a0, a1
;;       neg     a4, a5
;;       not     a5, a4
;;       and     a1, a0, a5
;;       sw      a3, 0(a1)
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
;;       slli    a4, a2, 0x20
;;       srli    a1, a4, 0x20
;;       lui     a4, 0x10
;;       addi    a2, a4, -4
;;       sltu    a5, a2, a1
;;       ld      a0, 0x50(a0)
;;       add     a0, a0, a1
;;       lui     a4, 0xffff
;;       slli    a1, a4, 4
;;       add     a0, a0, a1
;;       neg     a3, a5
;;       not     a5, a3
;;       and     a1, a0, a5
;;       lw      a0, 0(a1)
;;       ld      ra, 8(sp)
;;       ld      s0, 0(sp)
;;       addi    sp, sp, 0x10
;;       ret
