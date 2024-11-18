pub enum Step {
  Swap((Int, Int), (Int, Int), ~after: BoardArray)
  Revert((Int, Int), (Int, Int), ~after: BoardArray)
  Remove(Array[(Int, Int)], ~after: BoardArray)
  Fall(FixedArray[FixedArray[Byte]], FixedArray[FixedArray[Int]], ~after: BoardArray)
} derive(Show)

pub fn Board::do_move(
  self : Board,
  p1 : (Int, Int),
  p2 : (Int, Int)
) -> Array[Step] {
  let board_start = self.data.copy()

  // copy a draft board
  let mut board_curr = board_start
  let steps = []

  // do swap on draft board
  let (v1, v2) = (self.data[p1.0][p1.1], self.data[p2.0][p2.1])
  board_curr = board_curr.set(p2.0, board_curr[p2.0].set(p2.1, v1))
  board_curr = board_curr.set(p1.0, board_curr[p1.0].set(p1.1, v2))
  steps.push(Swap(p1, p2, after = board_curr))

  // loop for finding matches
  for {
    // find all matches
    let matches = find_matches(board_curr)
    if matches.length() == 0 {
      break // ends on no match
    }
    steps.push_iter(matches.iter())

    // remove panes from board
    for match_one in matches {
      match match_one {
        Remove(_panes, ~after) => {
          board_curr = after
        }
        _ => abort("matches only supports Remove")
      }
    }

    // drop panes and add fill new panes
    let (_board_after, step) = Board::drop_and_fall(board_curr)
    steps.push(step)
    match step {
      Fall(_, _, ~after) => {
        board_curr = after
      }
      _ => abort("step only supports Fall")
    }
  }

  // revert if no matches found (steps only contains a swap)
  if steps.length() == 1 {
    steps.push(Revert(p2, p1, after = board_start))
  }
  steps
}

fn Board::find_matches(board : BoardArray) -> Array[Step] {
  let removes = []
  let matches = []
  let mut board_curr = board
  let mut checked = BitBoard(0)

  // find all matches
  for {
    // find all cross matches first
    let (match_result, checked_after) = Board::next_match(board_curr, checked, cross = true)
    checked = checked_after
    match match_result {
      Some(Remove(panes, ~after) as _step) => {
        removes.push_iter(panes.iter())
        board_curr = after
        continue
      }
      _ => ()
    }

    // then find all line matches
    let (match_result, checked_after) = Board::next_match(board_curr, checked, line = true)
    checked = checked_after
    match match_result {
      Some(Remove(panes, ~after) as _step) => {
        removes.push_iter(panes.iter())
        board_curr = after
      }
      _ => break
    }
  }
  
  if removes.length() > 0 {
    matches.push(Remove(removes, after = board_curr))
  }
  matches
}

fn Board::next_match(
  board : BoardArray,
  marked : BitBoard,
  ~cross : Bool = false,
  ~line : Bool = false,
) -> (Step?, BitBoard) {
  let mut marked_curr = marked
  let fn_dirs = [
    fn(p : (Int, Int)) -> (Int, Int) { (p.0 - 1, p.1) },
    fn(p : (Int, Int)) -> (Int, Int) { (p.0 + 1, p.1) },
    fn(p : (Int, Int)) -> (Int, Int) { (p.0, p.1 - 1) },
    fn(p : (Int, Int)) -> (Int, Int) { (p.0, p.1 + 1) },
  ]
  // try every pane as starting
  for r = 0; r < BOARD_SIZE; r = r + 1 {
    for c = 0; c < BOARD_SIZE; c = c + 1 {
      // ignore already marked panes
      if marked_curr.get(r, c) {
        continue
      }
      // check matched panes in all four directions
      let cnt_dirs = Array::new(capacity=fn_dirs.length())
      for fn_dir in fn_dirs {
        let mut count = 0
        for p = fn_dir((r, c))
            0 <= p.0 && p.0 < BOARD_SIZE && 0 <= p.1 && p.1 < BOARD_SIZE
            p = fn_dir(p) {
          // note: marked pane can be included as a non-starting pane in a match
          if board[r][c] != board[p.0][p.1] {
            break
          }
          count += 1
        }
        cnt_dirs.push(count)
      }
      // is a crossing match if vertical 3 and horizonal 3 found
      if cross {
        if cnt_dirs[0] + cnt_dirs[1] >= 2 && cnt_dirs[2] + cnt_dirs[3] >= 2 {
          let panes = []
          panes.push((r, c))
          marked_curr = marked_curr.set(r, c, true)
          for i_cnt, cnt_dir in cnt_dirs.iter2() {
            let fn_dir = fn_dirs[i_cnt]
            let mut p = (r, c)
            for _cnt = 0; _cnt < cnt_dir; _cnt = _cnt + 1 {
              p = fn_dir(p)
              // note: marked pane in a match don't have to be included in removal result
              if marked_curr.get(p.0, p.1).not() {
                panes.push(p)
                marked_curr = marked_curr.set(p.0, p.1, true)
              }
            }
          }
          let board_after = Board::remove_panes(board, panes)
          return (Some(Step::Remove(panes, after = board_after)), marked_curr)
        }
      }
      // is a line match if only vertical 3 or horizonal 3 found
      if line {
        if cnt_dirs[0] + cnt_dirs[1] >= 2 && cnt_dirs[2] + cnt_dirs[3] < 2 {
          let panes = []
          panes.push((r, c))
          marked_curr = marked_curr.set(r, c, true)
          for i_cnt in [0, 1] {
            let (cnt_dir, fn_dir) = (cnt_dirs[i_cnt], fn_dirs[i_cnt])
            let mut p = (r, c)
            for _cnt = 0; _cnt < cnt_dir; _cnt = _cnt + 1 {
              p = fn_dir(p)
              if marked_curr.get(p.0, p.1).not() {
                panes.push(p)
                marked_curr = marked_curr.set(p.0, p.1, true)
              }
            }
          }
          let board_after = Board::remove_panes(board, panes)
          return (Some(Step::Remove(panes, after = board_after)), marked_curr)
        } else if cnt_dirs[0] + cnt_dirs[1] < 2 && cnt_dirs[2] + cnt_dirs[3] >= 2 {
          let panes = []
          panes.push((r, c))
          marked_curr = marked_curr.set(r, c, true)
          for i_cnt in [2, 3] {
            let (cnt_dir, fn_dir) = (cnt_dirs[i_cnt], fn_dirs[i_cnt])
            let mut p = (r, c)
            for _cnt = 0; _cnt < cnt_dir; _cnt = _cnt + 1 {
              p = fn_dir(p)
              if marked_curr.get(p.0, p.1).not() {
                panes.push(p)
                marked_curr = marked_curr.set(p.0, p.1, true)
              }
            }
          }
          let board_after = Board::remove_panes(board, panes)
          return (Some(Step::Remove(panes, after = board_after)), marked_curr)
        }
      }
      
    }
  }
  // no match
  (None, marked)
}

fn Board::remove_panes(board: BoardArray, panes: Array[(Int, Int)]) -> BoardArray {
  let mut board_curr = board
  for p in panes {
    board_curr = board_curr.set(p.0, board_curr[p.0].set(p.1, 0))
  }
  board_curr
}

fn Board::drop_and_fall(board : BoardArray) -> (BoardArray, Step) {
  let mut board_curr = board
  // fall existing panes from bottom
  let mut fall_dists = []
  for r = BOARD_SIZE - 1; r >= 0; r = r - 1 {
    let fall_dists_col = []
    for c = 0; c < BOARD_SIZE; c = c + 1 {
      fall_dists_col.push({
        if board_curr[r][c] != 0 {
          let mut empty_panes = 0
          for rt = r + 1; rt < BOARD_SIZE; rt = rt + 1 {
            if board_curr[rt][c] != 0 {
              break
            } else {
              empty_panes += 1
            }
          }
          let rt = r + empty_panes
          if empty_panes > 0 {
            let (v, vt) = (board_curr[r][c], board_curr[rt][c])
            board_curr = board_curr.set(rt, board_curr[rt].set(c, v))
            board_curr = board_curr.set(r, board_curr[r].set(c, vt))
          }
          empty_panes
        } else {
          0
        }
      })
    }
    fall_dists.push(FixedArray::from_array(fall_dists_col))
  }
  fall_dists = fall_dists.rev() // fix reverted index (r looped from bottom)

  let fall_count = FixedArray::makei(BOARD_SIZE, fn (c) -> Int {
    for r = 0; r < BOARD_SIZE; r = r + 1 {
      if board_curr[r][c] != 0 {
        return r
      }
    }
    BOARD_SIZE
  })

  let new_panes = []
  for c = 0; c < BOARD_SIZE; c = c + 1 {
    let count = fall_count[c]
    let new_panes_col = FixedArray::makei(count, fn (_r) {
      ((@common.rand() % GEM_TYPES) + 1).to_byte()
    })
    new_panes.push(new_panes_col)
    for r = 0; r < count; r = r + 1 {
      board_curr = board_curr.set(r, board_curr[r].set(c, new_panes_col[r]))
    }
  }
  let fall_step = Step::Fall(FixedArray::from_array(new_panes), FixedArray::from_array(fall_dists), after = board_curr)

  (board_curr, fall_step)
}
