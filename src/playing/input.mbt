fn Playing::input_a(self: Playing) -> Unit {
  match self.status {
    OPERATE => {
      if self.cursor.sel.not() {
        self.cursor.sel = true
      }
    }
    ANIMATE => ()
  }
}

fn Playing::input_b(self: Playing) -> Unit {
  match self.status {
    OPERATE => {
      if self.cursor.sel {
        self.cursor.sel = false
      }
    }
    ANIMATE => ()
  }
}

fn Playing::input_up(self: Playing) -> Unit {
  match self.status {
    OPERATE => {
      let r_new = self.cursor.r - 1
      if self.cursor.sel {
        if r_new >= 0 {
          let steps = self.board.val.do_move((self.cursor.r, self.cursor.c), (r_new, self.cursor.c))
          self.do_steps(steps)
        }
      } else {
        self.cursor.r = if r_new >= 0 { r_new } else { (@board.BOARD_SIZE - 1) }
      }
    }
    ANIMATE => ()
  }
}

fn Playing::input_down(self: Playing) -> Unit {
  match self.status {
    OPERATE => {
      let r_new = self.cursor.r + 1
      if self.cursor.sel {
        if r_new < @board.BOARD_SIZE {
          let steps = self.board.val.do_move((self.cursor.r, self.cursor.c), (r_new, self.cursor.c))
          self.do_steps(steps)
        }
      } else {
        self.cursor.r = if r_new < @board.BOARD_SIZE { r_new } else { 0 }
      }
    }
    ANIMATE => ()
  }
}

fn Playing::input_left(self: Playing) -> Unit {
  match self.status {
    OPERATE => {
      let c_new = self.cursor.c - 1
      if self.cursor.sel {
        if c_new >= 0 {
          let steps = self.board.val.do_move((self.cursor.r, self.cursor.c), (self.cursor.r, c_new))
          self.do_steps(steps)
        }
      } else {
        self.cursor.c = if c_new >= 0 { c_new } else { (@board.BOARD_SIZE - 1) }
      }
    }
    ANIMATE => ()
  }
}

fn Playing::input_right(self: Playing) -> Unit {
  match self.status {
    OPERATE => {
      let c_new = self.cursor.c + 1
      if self.cursor.sel {
        if c_new < @board.BOARD_SIZE {
          let steps = self.board.val.do_move((self.cursor.r, self.cursor.c), (self.cursor.r, c_new))
          self.do_steps(steps)
        }
      } else {
        self.cursor.c = if c_new < @board.BOARD_SIZE { c_new } else { 0 }
      }
    }
    ANIMATE => ()
  }
}
