let _rand_seed: Ref[Int] = Ref::new(1)

pub fn rand() -> Int {
  _rand_seed.val = (1103515245 * _rand_seed.val + 12345) & 0x7fffffff;
  return _rand_seed.val
}

/// Init randomizer with certain seed. 
pub fn srand(seed: Int) -> Unit {
  _rand_seed.val = seed
}
