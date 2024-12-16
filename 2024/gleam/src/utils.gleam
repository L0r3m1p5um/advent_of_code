pub fn power(x: Int, pow: Int) -> Int {
  do_power(x, pow, x)
}

fn do_power(x: Int, pow: Int, acc: Int) -> Int {
  case pow <= 1 {
    True -> acc
    False -> do_power(x, { pow - 1 }, acc * x)
  }
}
