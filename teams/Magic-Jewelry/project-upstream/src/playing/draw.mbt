const BOARD_X: Int = 16
const BOARD_Y: Int = 25
const PANE_SIZE: Int = 16
const CURSOR_SIZE: Int = 17

pub struct Draw {
  atlas_jewels : @wasm4.Sprite
  atlas_cursor : @wasm4.Sprite
}

pub fn Draw::new() -> Draw {
  {
    atlas_jewels: @wasm4.sprite(@common.ATLAS_PANES),
    atlas_cursor: @wasm4.sprite(@common.ATLAS_CURSOR),
  }
}

fn Draw::draw_bg(_self: Draw, matched: Int) -> Unit {
  {
    @wasm4.set_draw_colors(3, index=1)
    @wasm4.set_draw_colors(0, index=2)

    @wasm4.text("MATCHED: \{matched}", 24, 8)
  }
  {
    @wasm4.set_draw_colors(0, index=1)
    @wasm4.set_draw_colors(2, index=2)
    @wasm4.rect(13, 22, 132, 132)
  }
}

fn Draw::draw_board_cursor(self: Draw, board: @board.Board, cursor: Cursor?) -> Unit {
  Draw::set_pane_colors()
  for r = 0; r < 8; r = r + 1 {
    for c = 0; c < 8; c = c + 1 {
      if board.hide.get(r, c) {
        continue
      }
      let (x, y) = Draw::pane_pos(r, c)
      self.draw_pane(x, y, board.get(r, c))
    }
  }

  match cursor {
    Some(cursor) => {
      @wasm4.set_draw_colors(0, index=1)
      @wasm4.set_draw_colors(4, index=2)
      let x = BOARD_X + cursor.c * PANE_SIZE - 1
      let y = BOARD_Y + cursor.r * PANE_SIZE - 1
      let src_x = if cursor.sel { CURSOR_SIZE } else { 0 }
      self.atlas_cursor.blit_sub(x, y, CURSOR_SIZE, CURSOR_SIZE, src_x, 0, 48, @common.sprite_1bpp)
    }
    _ => ()
  }
}

pub fn Draw::set_pane_colors() -> Unit {
  @wasm4.set_draw_colors(0, index=1)
  @wasm4.set_draw_colors(2, index=2)
  @wasm4.set_draw_colors(3, index=3)
  @wasm4.set_draw_colors(4, index=4)
}

pub fn Draw::draw_pane(self: Draw, x: Int, y: Int, v: Byte, ~variant: Int = 0) -> Unit {
  let isprite = v.to_int() - 1
  // ensure sprite valid
  if isprite < 0 || isprite >= @board.GEM_TYPES {
    return
  }
  let sprite_x = variant * PANE_SIZE
  if sprite_x >= @common.ATLAS_PANES_WIDTH {
    return
  }
  // avoid overflow the board (top only)
  let mut y_board = y
  let mut y_sprite = isprite * PANE_SIZE
  let mut h_sprite = PANE_SIZE
  if y < BOARD_Y {
    let y_cutoff = BOARD_Y - y
    if y_cutoff >= PANE_SIZE {
      return  // all the sprite doesn't need draw
    }
    y_board += y_cutoff
    y_sprite += y_cutoff
    h_sprite -= y_cutoff
  }

  // draw sprite
  self.atlas_jewels.blit_sub(
    x,
    y_board,
    PANE_SIZE,
    h_sprite,
    sprite_x,
    y_sprite,
    @common.ATLAS_PANES_WIDTH,
    @common.sprite_2bpp,
  )
}

fn Draw::pane_pos(r: Int, c: Int) -> (Int, Int) {
  (BOARD_X + c * 16, BOARD_Y + r * 16)
}
