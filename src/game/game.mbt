pub struct Game {
  mut scene : @common.Scene
}

pub fn Game::new() -> Game {
  let scene = @title.Title::new()
  Game::{ scene }
}

pub fn Game::start(self: Game) -> Unit {                     
  self.scene.start()

  @common.event_sub(EVENT_START_GAME, fn () {
    @common.srand(@common.frame().reinterpret_as_int())
    // @common.srand(1011)
    self.scene = @playing.Playing::new()
    self.scene.start()
  })

  @wasm4.set_palette(1, @wasm4.rgb(0xdde3ed))
  @wasm4.set_palette(2, @wasm4.rgb(0x9dacc9))
  @wasm4.set_palette(3, @wasm4.rgb(0x486699))
  @wasm4.set_palette(4, @wasm4.rgb(0x0f2c5c))
}

pub fn Game::upd(self : Game) -> Unit {
  self.scene.upd()
}

