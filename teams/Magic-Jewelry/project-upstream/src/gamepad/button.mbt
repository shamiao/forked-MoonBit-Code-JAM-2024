pub enum BUTTON {
  BUTTON_1
  BUTTON_2
  BUTTON_LEFT
  BUTTON_RIGHT
  BUTTON_UP
  BUTTON_DOWN
} derive(Eq)

struct Button {
  index : BUTTON
  mut frame: UInt
  mut status : Byte
  mut handler : (() -> Unit)?
}

fn Button::is_down(self : Button, gamepad : @wasm4.GamePad) -> Bool {
  match self.index {
    BUTTON_1 => gamepad.button_1
    BUTTON_2 => gamepad.button_2
    BUTTON_UP => gamepad.button_up
    BUTTON_DOWN => gamepad.button_down
    BUTTON_LEFT => gamepad.button_left
    BUTTON_RIGHT => gamepad.button_right
  }
}
