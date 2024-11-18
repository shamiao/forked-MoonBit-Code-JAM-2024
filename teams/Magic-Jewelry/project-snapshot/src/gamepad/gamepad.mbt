pub const BUTTON_REPEAT_DELAY: UInt = 22
pub const BUTTON_REPEAT_RATE: UInt = 12

pub struct GamePad {
  index : UInt
  buttons : Array[Button]
}

pub fn GamePad::new(~index : UInt = 1) -> GamePad {
  let buttons = [
    Button::{ index: BUTTON_1, frame: 0, status: 0, handler: None },
    Button::{ index: BUTTON_2, frame: 0, status: 0, handler: None },
    Button::{ index: BUTTON_LEFT, frame: 0, status: 0, handler: None },
    Button::{ index: BUTTON_RIGHT, frame: 0, status: 0, handler: None },
    Button::{ index: BUTTON_UP, frame: 0, status: 0, handler: None },
    Button::{ index: BUTTON_DOWN, frame: 0, status: 0, handler: None },
  ]
  GamePad::{ index, buttons }
}

pub fn GamePad::map(
  self : GamePad,
  key : BUTTON,
  handler : () -> Unit
) -> Unit {
  for button in self.buttons {
    if button.index == key {
      button.handler = Some(handler)
    }
  }
}

pub fn GamePad::upd(self: GamePad) -> Unit {
  let w4_gamepad = @wasm4.get_gamepad(index = self.index)
  for button in self.buttons {
    match button.handler {
      Some(handler) => {
        let keydown = button.is_down(w4_gamepad)
        if keydown {
          match button.status {
            0 => {
              button.frame = @common.frame()
              handler()
              button.status = 1
            }
            1 => {
              if @common.frame() > button.frame && (@common.frame() - button.frame) > BUTTON_REPEAT_DELAY {
                button.frame = @common.frame()
                handler()
                button.status = 2
              }
            }
            2 => {
              if @common.frame() > button.frame && (@common.frame() - button.frame) > BUTTON_REPEAT_RATE {
                button.frame = @common.frame()
                handler()
              }
            }
            _ => button.status = 0
          }
        } else {
          button.status = 0
        }
      }
      None => ()
    }
  }
}
