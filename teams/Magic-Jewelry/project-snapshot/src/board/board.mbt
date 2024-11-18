
pub const BOARD_SIZE = 8
pub const GEM_TYPES = 5

typealias BoardArray = @immut/array.T[@immut/array.T[Byte]]

pub struct Board {
  mut hide: BitBoard
  mut data: BoardArray
  mut matched: Int
}

pub fn Board::new() -> Board {
  let r = {
    hide: BitBoard(0),
    data: @immut/array.new(),
    matched: 0,
  }
  r.fill_randomize()
  r
}

pub fn Board::to_string(self: Board) -> String {
  let mut s = ""
  for r = 0; r < BOARD_SIZE; r = r + 1 {
    let mut s_line = ""
    for c = 0; c < BOARD_SIZE; c = c + 1 {
      s_line += self.data[r][c].to_int().to_string()
    }
    s += "\{s_line}\n"
  }
  s
}

pub fn Board::get(self: Board, r: Int, c: Int) -> Byte {
  self.data[r][c]
}

fn Board::fill_randomize(self: Board) -> Unit {
  // create temp mut array
  let data = FixedArray::makei(BOARD_SIZE, fn (_r) {
    FixedArray::make(BOARD_SIZE, b'\x00')
  })
  // clear the board
  for r = 0; r < BOARD_SIZE; r = r + 1 {
    for c = 0; c < BOARD_SIZE; c = c + 1 {
      data[r][c] = 0
    }
  }
  // set the board from bottom row
  for r = BOARD_SIZE - 1; r >= 0; r = r - 1 {
    for c = 0; c < BOARD_SIZE; c = c + 1 {
      data[r][c] = {
        let mut curr = b'\x00'
        for {
          // check has match downwards or has match leftwards
          curr = ((@common.rand() / 17 % GEM_TYPES) + 1).to_byte()
          if ((r + 2 < BOARD_SIZE) && (curr == data[r + 1][c] && curr == data[r + 2][c])) || 
            ((c - 2 >= 0) && (curr == data[r][c - 1] && curr == data[r][c - 2])) {
            continue
          } else {
            break
          }
        }
        curr
      }
    }
  }

  // convert to immut array
  self.data = @immut/array.makei(BOARD_SIZE, fn (r){
    @immut/array.from_iter(data[r].iter())
  })
}
