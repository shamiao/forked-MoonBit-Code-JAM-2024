let _frame : Ref[UInt] = Ref::new(0)

pub fn frame() -> UInt {
  _frame.val
}

pub fn frame_upd() -> Unit {
  _frame.update(fn(x) { x + 1 })
}
