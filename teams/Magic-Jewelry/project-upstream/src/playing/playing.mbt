enum Status {
  OPERATE
  ANIMATE
}

struct Cursor {
  mut r : Int
  mut c : Int
  mut sel : Bool
}

pub struct Playing {
  draw : Draw
  mut status : Status
  cursor : Cursor
  animate : Animate
  board : Ref[@board.Board]
  gamepad : @gamepad.GamePad
}

pub fn Playing::new() -> Playing {
  let draw = Draw::new()
  let board = Ref::new(@board.Board::new())
  let status = OPERATE
  let animate = Animate::new(draw, board)
  let cursor = { r: 0, c: 0, sel: false }
  let gamepad = @gamepad.GamePad::new()
  Playing::{ draw, status, animate, cursor, board, gamepad }
}

pub fn Playing::start(self : Playing) -> Unit {
  self.gamepad.map(@gamepad.BUTTON_1, fn() { self.input_a() })
  self.gamepad.map(@gamepad.BUTTON_2, fn() { self.input_b() })
  self.gamepad.map(@gamepad.BUTTON_UP, fn() { self.input_up() })
  self.gamepad.map(@gamepad.BUTTON_DOWN, fn() { self.input_down() })
  self.gamepad.map(@gamepad.BUTTON_LEFT, fn() { self.input_left() })
  self.gamepad.map(@gamepad.BUTTON_RIGHT, fn() { self.input_right() })
  
  @common.event_sub(EVENT_ANIMATE_END, fn () {
    self.status = OPERATE
  })

  self.start_fall_all()
}

pub fn Playing::upd(self : Playing) -> Unit {
  self.draw.draw_bg(self.board.val.matched)
  match self.status {
    OPERATE => {
      self.draw.draw_board_cursor(self.board.val, Some(self.cursor))
    }
    ANIMATE => {
      self.animate.upd()
    }
  }
  self.gamepad.upd()
}

fn Playing::do_steps(self : Playing, steps : Array[@board.Step]) -> Unit {
  self.cursor.sel = false
  self.animate.start(steps)
  self.status = ANIMATE
}

fn Playing::start_fall_all(self: Playing) -> Unit {
  let board = self.board.val.data
  let fall_arr = []
  for c = 0; c < @board.BOARD_SIZE; c = c + 1 {
    let fall_col = []
    for r = 0; r < @board.BOARD_SIZE; r = r + 1 {
      fall_col.push(board[r][c])
    }
    fall_arr.push(FixedArray::from_array(fall_col))
  }
  let fall_arr = FixedArray::from_array(fall_arr)
  let fall_dist_arr = FixedArray::makei(@board.BOARD_SIZE, fn (_i) {
    FixedArray::make(@board.BOARD_SIZE, 0)
  })
  
  self.board.val.data = @immut/array.makei(@board.BOARD_SIZE, fn (_i) {
    @immut/array.make(@board.BOARD_SIZE, 0)
  })
  let step = @board.Step::Fall(fall_arr, fall_dist_arr, after = board)

  self.do_steps([step])
}