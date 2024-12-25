import gleam/list

pub fn power(x: Int, pow: Int) -> Int {
  do_power(x, pow, x)
}

fn do_power(x: Int, pow: Int, acc: Int) -> Int {
  case pow <= 1 {
    True -> acc
    False -> do_power(x, { pow - 1 }, acc * x)
  }
}

pub fn all_coordinates(dimensions: #(Int, Int)) -> List(#(Int, Int)) {
  use x <- list.flat_map(list.range(0, dimensions.0))
  use y <- list.map(list.range(0, dimensions.1))
  #(x, y)
}
