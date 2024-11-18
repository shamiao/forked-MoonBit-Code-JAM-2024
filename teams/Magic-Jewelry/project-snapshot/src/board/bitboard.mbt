pub type BitBoard UInt64

pub fn BitBoard::get(self : BitBoard, r : Int, c : Int) -> Bool {
  assert_true?(0 <= r && r < BOARD_SIZE && 0 <= c && c < BOARD_SIZE).unwrap()
  let index = r * BOARD_SIZE + c
  (self._ & (1UL << index)) != 0UL
}

pub fn BitBoard::set(self : BitBoard, r : Int, c : Int, val : Bool) -> BitBoard {
  assert_true?(0 <= r && r < BOARD_SIZE && 0 <= c && c < BOARD_SIZE).unwrap()
  let index = r * BOARD_SIZE + c
  BitBoard(
    if val {
      self._ | (1UL << index)
    } else {
      self._ & (1UL << index).lnot()
    },
  )
}
