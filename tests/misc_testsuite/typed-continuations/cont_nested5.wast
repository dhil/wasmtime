;; test using continuations from within a continuation


(module

  (type $unit_to_unit (func))
  (type $ct (cont $unit_to_unit))

  (type $g2_res_type (func (result (ref $ct))))
  (type $g2_res_type_ct (cont $g2_res_type))

  (tag $e1)
  (tag $e2 (param (ref $ct)))

  (global $marker (mut i32) (i32.const 0))

  (func $update_marker (param $x i32)
    (i32.add (global.get $marker) (i32.const 1))
    (i32.mul (local.get $x))
    (global.set $marker))

  (func $g1
    (call $update_marker (i32.const 2))
    (suspend $e1)
    (call $update_marker (i32.const 3))
    )
  (elem declare func $g1)

  (func $g2 (result (ref $ct))
    (local $k1 (ref $ct))
    (local $k2 (ref $ct))
    (call $update_marker (i32.const 5))

    (block $on_e1 (result (ref $ct))
      (resume $ct (on $e1 $on_e1) (cont.new $ct (ref.func $g1)))
      (unreachable))
    (local.set $k1)
    (call $update_marker (i32.const 7))
    (block $on_e1_2 (result (ref $ct))
      (resume $ct (on $e1 $on_e1_2) (cont.new $ct (ref.func $g1)))
      (unreachable))
    (local.set $k2)
    (call $update_marker (i32.const 11))
    (resume $ct (local.get $k1))
    (call $update_marker (i32.const 13))
    (local.get $k2)
    )
  (elem declare func $g2)

  (func $g3
    (call $update_marker (i32.const 17))
    (resume $g2_res_type_ct (cont.new $g2_res_type_ct (ref.func $g2)))
    (call $update_marker (i32.const 19))
    (suspend $e2))
  (elem declare func $g3)


  (func $test (export "test") (result i32)
    (call $update_marker (i32.const 23))
    (block $on_e2 (result (ref $ct) (ref $ct))
      (resume $ct (on $e2 $on_e2) (cont.new $ct (ref.func $g3)))
      (unreachable))
    (drop) ;; we won't resume g3, but want the payload
    (call $update_marker (i32.const 31))
    (resume $ct)
    (global.get $marker)))

(assert_return (invoke "test") (i32.const 490_074_902))
