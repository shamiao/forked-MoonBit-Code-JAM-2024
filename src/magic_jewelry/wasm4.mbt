let game : Ref[@game.Game] = Ref::new(@game.Game::new())
pub fn start() -> Unit {
  game.val.start()
}

pub fn upd() -> Unit {
  @common.frame_upd()
  game.val.upd()
}
