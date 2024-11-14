pub enum EVENT_ID {
  EVENT_START_GAME
  EVENT_ANIMATE_END
} derive(Eq, Hash)

let _event_handler : Map[EVENT_ID, () -> Unit] = { }

pub fn event_sub(event: EVENT_ID, callback : () -> Unit) -> Unit {
  _event_handler[event] = callback
}

pub fn event(event : EVENT_ID) -> Unit {
  guard let Some(handler) = _event_handler.get(event) else { _ => return }
  handler()
}
