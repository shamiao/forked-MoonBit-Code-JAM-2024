pub struct Title {
  draw: @playing.Draw
  gamepad: @gamepad.GamePad
}

pub fn Title::new() -> Title {
  let draw = @playing.Draw::new()
  let gamepad = @gamepad.GamePad::new()
  Title::{ gamepad, draw }
}

pub fn Title::start(self: Title) -> Unit {
  self.gamepad.map(@gamepad.BUTTON_1, start_game)
  self.gamepad.map(@gamepad.BUTTON_2, start_game)
  self.gamepad.map(@gamepad.BUTTON_UP, start_game)
  self.gamepad.map(@gamepad.BUTTON_DOWN, start_game)
  self.gamepad.map(@gamepad.BUTTON_LEFT, start_game)
  self.gamepad.map(@gamepad.BUTTON_RIGHT, start_game)
}

pub fn Title::upd(self: Title) -> Unit {
  @wasm4.set_draw_colors(4, index = 1)
  @wasm4.set_draw_colors(0, index = 2)
  @wasm4.text("   MAGIC JEWELRY   ", 4, 40)
  @wasm4.text("   PRESS ANY KEY   ", 4, 120)

  @playing.Draw::set_pane_colors()
  for i = 0; i < 5; i = i + 1 {
    self.draw.draw_pane(40 + i * 16, 70, (i + 1).to_byte())
  }

  self.gamepad.upd()
}

fn start_game() -> Unit {
  @common.event(EVENT_START_GAME)
}
