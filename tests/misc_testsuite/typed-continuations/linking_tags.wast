(module $foo
  (tag $foo (export "foo"))
)
(register "foo")

(module $bar
  (type $ft (func))
  (type $ct (cont $ft))
  (tag $foo (import "foo" "foo"))
  (tag $bar)
  (func $do_foo
    (suspend $foo))

  ;; Don't handle the imported foo.
  (func (export "main-1")
    (block $on_bar (result (ref $ct))
      (resume $ct (tag $bar $on_bar) (cont.new $ct (ref.func $do_foo)))
      (unreachable)
    )
    (unreachable))

  ;; Handle the imported foo.
  (func (export "main-2")
    (block $on_foo (result (ref $ct))
      (resume $ct (tag $foo $on_foo) (cont.new $ct (ref.func $do_foo)))
      (unreachable)
    )
    (drop))

  (elem declare func $do_foo)
)
(register "bar")
(assert_suspension (invoke "main-1") "unhandled")
(assert_return (invoke "main-2"))