const ANIMATE_SWAP_FRAME = 20U
const ANIMATE_SWAP_DURATION = 30U
const ANIMATE_REMOVE_FRAME_STEP = 6U
const ANIMATE_REMOVE_STEPS = 3
const ANIMATE_REMOVE_DURATION = 28U
const ANIMATE_FALL_GRAVITY = 1
const ANIMATE_FALL_GRAVITY_FRAC = 20
const ANIMATE_FALL_MAX_DURATION = 120U
const ANIMATE_FALL_WAIT_AFTER_OVER = 20U

struct AnimatePaneFall {
  val: Byte
  x: Int
  y_from: Int
  y_to: Int
} derive(Show)

struct Animate {
  draw : Draw
  board : Ref[@board.Board]
  steps : Ref[Array[@board.Step]]
  mut running: Bool
  mut curr_step : Int
  mut frame_step : UInt
  mut fall : Array[AnimatePaneFall]
  mut fall_over_at : UInt
}

fn Animate::new(draw : Draw, board : Ref[@board.Board]) -> Animate {
  let steps = Ref::new([])
  let curr_step = 0
  let frame_step = 0U
  let running = false
  let fall = []
  let fall_over_at = 0U
  { draw, board, steps, running, curr_step, frame_step, fall, fall_over_at }
}

fn Animate::start(self : Animate, steps : Array[@board.Step]) -> Unit {
  self.steps.val = steps
  self.running = true
  self.advance_to_step(0)
}

fn Animate::upd(self : Animate) -> Unit {
  if self.running.not() || self.steps.val.length() == 0 {
    return
  }

  if 0 <= self.curr_step && self.curr_step < self.steps.val.length() {
    let step = self.steps.val[self.curr_step]
    let step_end = {
      let step_duration = match step {
        Swap(_, _, ..) => ANIMATE_SWAP_DURATION
        Revert(_, _, ..) => ANIMATE_SWAP_DURATION
        Remove(_, ..) => ANIMATE_REMOVE_DURATION
        Fall(_, _, ..) => ANIMATE_FALL_MAX_DURATION
      }
      let time_over = @common.frame() - self.frame_step > step_duration
      match step {
        Fall(_, _, ..) => {
          time_over || (self.fall_over_at > 0 && ((@common.frame() - self.fall_over_at) >
            ANIMATE_FALL_WAIT_AFTER_OVER))
        }
        _ => time_over
      }
    }
    if step_end {
      // end step, update board to after step status
      self.board.val.data = match step {
        Swap(_, _, ~after) => after
        Revert(_, _, ~after) => after
        Remove(_, ~after) => after
        Fall(_, _, ~after) => after
      }
      match step {
        Fall(_, _, ..) => self.fall.clear()
        _ => ()
      }
      // go to next step
      self.advance_to_step(self.curr_step + 1)
    }
  } else {
    self.running = false
    self.steps.val.clear()
    @common.event(EVENT_ANIMATE_END)
  }

  self.draw()
}

fn Animate::advance_to_step(self: Animate, step_index: Int) -> Unit {
  self.curr_step = step_index
  self.frame_step = @common.frame()
  self.board.val.hide = @board.BitBoard(0UL)

  if 0 <= step_index && step_index < self.steps.val.length() {
    let step = self.steps.val[step_index]
    // start step, init data
    match step {
      Swap((r1, c1), (r2, c2), ..) | Revert((r1, c1), (r2, c2), ..) => {
        self.board.val.hide = self.board.val.hide.set(r1, c1, true)
        self.board.val.hide = self.board.val.hide.set(r2, c2, true)
      }
      Remove(panes, ..) => {
        let mut hide = @board.BitBoard(0UL)
        self.board.val.matched += panes.length()
        for pane in panes {
          hide = hide.set(pane.0, pane.1, true)
        }
        self.board.val.hide = hide
      }
      Fall(_, ..) => {
        self.start_fall(step)
      }
    }

    // @wasm4.trace("advanced to step \{step_index} \{step}")
  } else {
    // @wasm4.trace("advanced to step END")
  }
}

fn Animate::draw(self : Animate) -> Unit {
  let frame = @common.frame() - self.frame_step
  if 0 <= self.curr_step && self.curr_step < self.steps.val.length() {
    let step = self.steps.val[self.curr_step]
    match step {
      Swap((r1, c1), (r2, c2), ..) | Revert((r1, c1), (r2, c2), ..) => {
        Draw::set_pane_colors()
        let s1 = Draw::pane_pos(r1, c1)
        let s2 = Draw::pane_pos(r2, c2)
        let p1 = (
          s1.0 +
          (s2.0 - s1.0) *
          @math.minimum(frame.reinterpret_as_int(), ANIMATE_SWAP_FRAME.reinterpret_as_int()) /
          ANIMATE_SWAP_FRAME.reinterpret_as_int(),
          s1.1 +
          (s2.1 - s1.1) *
          @math.minimum(frame.reinterpret_as_int(), ANIMATE_SWAP_FRAME.reinterpret_as_int()) /
          ANIMATE_SWAP_FRAME.reinterpret_as_int(),
        )
        let p2 = (
          s2.0 +
          (s1.0 - s2.0) *
          @math.minimum(frame.reinterpret_as_int(), ANIMATE_SWAP_FRAME.reinterpret_as_int()) /
          ANIMATE_SWAP_FRAME.reinterpret_as_int(),
          s2.1 +
          (s1.1 - s2.1) *
          @math.minimum(frame.reinterpret_as_int(), ANIMATE_SWAP_FRAME.reinterpret_as_int()) /
          ANIMATE_SWAP_FRAME.reinterpret_as_int(),
        )
        self.draw.draw_pane(p1.0, p1.1, self.board.val.get(r1, c1))
        self.draw.draw_pane(p2.0, p2.1, self.board.val.get(r2, c2))
      }
      Remove(panes, ..) => {
        Draw::set_pane_colors()
        let step = (frame / ANIMATE_REMOVE_FRAME_STEP).reinterpret_as_int()
        if step < ANIMATE_REMOVE_STEPS {
          // @wasm4.trace("REMOVAL STEP \{step}")
          for p in panes {
            let (x, y) = Draw::pane_pos(p.0, p.1)
            self.draw.draw_pane(x, y, self.board.val.get(p.0, p.1), variant = step)
          }
        }
      }
      Fall(_, _, ..) => {
        let mut fall_over_count = 0
        for fall in self.fall {
          let mut y = fall.y_from + (ANIMATE_FALL_GRAVITY * frame.reinterpret_as_int() * 
            frame.reinterpret_as_int() / ANIMATE_FALL_GRAVITY_FRAC)
          if y >= fall.y_to {
            y = fall.y_to
            fall_over_count += 1
          }
          self.draw.draw_pane(fall.x, y, fall.val)
        }
        if self.fall_over_at == 0 && fall_over_count >= self.fall.length() {
          // @wasm4.trace("fall over at:\{@common.frame()}")
          self.fall_over_at = @common.frame()
        }
      }
    }
  }

  self.draw.draw_board_cursor(self.board.val, None)
}

fn Animate::start_fall(self: Animate, step: @board.Step) -> Unit {
  let falls = []
  let board = self.board.val.data.copy()
  guard let Fall(new_panes, fall_dists, ..) = step

  // fall existing panes
  // @wasm4.trace("board:\{board}")
  let mut hide = @board.BitBoard(0UL)
  for r = 0; r < @board.BOARD_SIZE; r = r + 1 {
    for c = 0; c < @board.BOARD_SIZE; c = c + 1 {
      if fall_dists[r][c] > 0 {
        // @wasm4.trace("fall existing r\{r} c\{c} (to r\{r + fall_dists[r][c]})")
        let p_from = Draw::pane_pos(r, c)
        let p_to = Draw::pane_pos(r + fall_dists[r][c], c)
        let fall = AnimatePaneFall::{
          val: board[r][c],
          x: p_from.0,
          y_from: p_from.1,
          y_to: p_to.1,
        }
        falls.push(fall)
        // @wasm4.trace("fall existing: \{fall}")
        hide = hide.set(r, c, true)
      }
    }
  }
  self.board.val.hide = hide
  
  // fall new panes
  for c = 0; c < @board.BOARD_SIZE; c = c + 1 {
    for r_to = 0; r_to < new_panes[c].length(); r_to = r_to + 1 {
      // @wasm4.trace("fill \{c} \{r_to}")
      let r = (-new_panes[c].length()) + r_to
      // @wasm4.trace(" NEW r=\{r}->\{r_to} c=\{c}")
      let p_from = Draw::pane_pos(r, c)
      let p_to = Draw::pane_pos(r_to, c)
      // @wasm4.trace(" NEW y=\{p_from.1}->\{p_to.1}")
      let fall = AnimatePaneFall::{
        val: new_panes[c][r_to],
        x: p_from.0,
        y_from: p_from.1,
        y_to: p_to.1,
      }
      falls.push(fall)
      // @wasm4.trace("fall: \{fall}")
    }
  }

  self.fall = falls
  self.fall_over_at = 0
}
