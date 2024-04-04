;;! target = "riscv64"
;;! test = "compile"
;;! flags = " -C cranelift-enable-heap-access-spectre-mitigation=false -O static-memory-forced -O static-memory-guard-size=0 -O dynamic-memory-guard-size=0"

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
;;       slli    a1, a2, 0x20
;;       srli    a2, a1, 0x20
;;       lui     a1, 0x10
;;       addi    a4, a1, -4
;;       bltu    a4, a2, 0x2c
;;       ld      a4, 0x60(a0)
;;       add     a2, a4, a2
;;       lui     a1, 0xffff
;;       slli    a4, a1, 4
;;       add     a2, a2, a4
;;       sw      a3, 0(a2)
;;       ld      ra, 8(sp)
;;       ld      s0, 0(sp)
;;       addi    sp, sp, 0x10
;;       ret
;;       .byte   0x00, 0x00, 0x00, 0x00
;;
;; wasm[0]::function[1]:
;;       addi    sp, sp, -0x10
;;       sd      ra, 8(sp)
;;       sd      s0, 0(sp)
;;       mv      s0, sp
;;       slli    a1, a2, 0x20
;;       srli    a2, a1, 0x20
;;       lui     a1, 0x10
;;       addi    a3, a1, -4
;;       bltu    a3, a2, 0x2c
;;       ld      a3, 0x60(a0)
;;       add     a2, a3, a2
;;       lui     a1, 0xffff
;;       slli    a3, a1, 4
;;       add     a2, a2, a3
;;       lw      a0, 0(a2)
;;       ld      ra, 8(sp)
;;       ld      s0, 0(sp)
;;       addi    sp, sp, 0x10
;;       ret
;;       .byte   0x00, 0x00, 0x00, 0x00
