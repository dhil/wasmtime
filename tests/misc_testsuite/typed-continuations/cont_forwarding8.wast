;; The resumed continuation suspends again, to the same and different tags.
;; We use the same outer handler in a loop

(module

  (type $int_to_int (func (param i32) (result i32)))
  (type $unit_to_int (func (result i32)))
  (type $ct0 (cont $int_to_int))

  (tag $e1 (param i32) (result i32))
  (tag $e2 (param i32) (result i32))

  (func $g1 (param $x i32) (result i32)
    (i32.add (local.get $x) (i32.const 1))
    (suspend $e1)
    (i32.add (i32.const 1))
    (suspend $e2)
    (i32.add (i32.const 1))
    (suspend $e1)
    (i32.add (i32.const 1)))
  (elem declare func $g1)

  ;; Calls $g1 as continuation, but only handles e2 rather than e1
  (func $g2 (param $x i32) (result i32)
    (local $k1 (ref $ct0))
    (block $on_e2 (result i32 (ref $ct0))
      (i32.add (local.get $x) (i32.const 1))
      (resume $ct0 (tag $e2 $on_e2) (cont.new $ct0 (ref.func $g1)))
      (unreachable))
    (local.set $k1)

    ;; we expect to suspend to $e2 eventually, at which point we install a new handler, while keeping the
    ;; "outer" one for $e1 intact.
    (i32.add (i32.const 1))
    (block $on_e2_2 (param i32) (result i32 (ref $ct0))
      (resume $ct0 (tag $e2 $on_e2_2) (local.get $k1))
      (i32.add (i32.const 1))
      (suspend $e1)
      (i32.add (i32.const 1))
      (return))
    (unreachable))
  (elem declare func $g2)

  (func $g3 (param $x i32) (result i32)
     (local $k1 (ref $ct0))
     (local.get $x)
     (cont.new $ct0 (ref.func $g2))

     (loop $loop (param i32 (ref $ct0))
       (block $on_e1 (param i32 (ref $ct0)) (result i32 (ref $ct0))
         (resume $ct0 (tag $e1 $on_e1))
         (return))
       (local.set $k1)
       (i32.add (i32.const 1))
       (local.get $k1)
       (br $loop))
     (unreachable))

  (func $test (export "test") (result i32)
    (call $g3 (i32.const 1))))

(assert_return (invoke "test") (i32.const 12))
