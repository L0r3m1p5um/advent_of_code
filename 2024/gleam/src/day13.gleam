import gleam/bool
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{Some}
import gleam/regex
import gleam/result
import gleam/string
import simplifile

pub fn main() {
  let input = read_input("inputs/day13/input.txt")
  io.println("Part 1")
  part1(input) |> io.debug
  io.println("Part 2")
  part2(input) |> io.debug
}

pub type Game {
  Game(prize: #(Int, Int), button_a: #(Int, Int), button_b: #(Int, Int))
}

pub fn part1(games: List(Game)) -> Int {
  games
  |> list.map(fn(game) {
    solve_game(game)
    |> result.map(fn(it) { { it.0 * 3 } + it.1 })
    |> result.unwrap(0)
  })
  |> int.sum
}

pub fn part2(games: List(Game)) -> Int {
  games
  |> list.map(fn(game) {
    Game(
      ..game,
      prize: add(game.prize, #(10_000_000_000_000, 10_000_000_000_000)),
    )
  })
  |> part1
}

fn solve_game(game: Game) -> Result(#(Int, Int), Nil) {
  let Game(#(prize_x, prize_y), #(a_x, a_y), #(b_x, b_y)) = game
  solve_equation(#(#(a_x, b_x), prize_x), #(#(a_y, b_y), prize_y))
}

// Solves the equation via gaussian elimination
fn solve_equation(
  x_component: #(#(Int, Int), Int),
  y_component: #(#(Int, Int), Int),
) -> Result(#(Int, Int), Nil) {
  let row_mult = fn(it: #(#(Int, Int), Int), scalar: Int) {
    #(mult(it.0, scalar), { it.1 * scalar })
  }
  let row_add = fn(row1: #(#(Int, Int), Int), row2: #(#(Int, Int), Int)) {
    let #(#(x1, y1), z1) = row1
    let #(#(x2, y2), z2) = row2
    #(#({ x1 + x2 }, { y1 + y2 }), { z1 + z2 })
  }
  let #(#(a1, b1), _) = x_component
  let #(#(a2, _), _) = y_component
  // Multiply the second row so that the first row can be subtracted
  // with an integer scalar
  let y1 = row_mult(y_component, a1)
  // Remove the a component from the second row
  let #(#(_, y2_b), y2_c) = row_add(y1, row_mult(x_component, int.negate(a2)))
  // make sure an integer solution to b exists
  use <- bool.guard(int.remainder(y2_c, y2_b) != Ok(0), Error(Nil))
  let b_solution = y2_c / y2_b

  // remove the b component from the first row
  let #(#(x2_a, _), x2_c) =
    row_add(x_component, row_mult(#(#(0, 1), b_solution), int.negate(b1)))
  // make sure an integer solution to a exists
  use <- bool.guard(int.remainder(x2_c, x2_a) != Ok(0), Error(Nil))
  let a_solution = x2_c / x2_a
  Ok(#(a_solution, b_solution))
}

fn add(x: #(Int, Int), y: #(Int, Int)) -> #(Int, Int) {
  #({ x.0 + y.0 }, { x.1 + y.1 })
}

fn mult(pair: #(Int, Int), scalar: Int) -> #(Int, Int) {
  #({ pair.0 * scalar }, { pair.1 * scalar })
}

pub fn read_input(filename: String) -> List(Game) {
  let assert Ok(content) = simplifile.read(filename)
  content
  |> string.trim
  |> string.split("\n\n")
  |> list.map(parse_game)
}

fn parse_game(input: String) -> Game {
  let assert Ok(re) =
    regex.compile(
      "Button A: X\\+(\\d+), Y\\+(\\d+)\\n"
        <> "Button B: X\\+(\\d+), Y\\+(\\d+)\\n"
        <> "Prize: X=(\\d+), Y=(\\d+)",
      regex.Options(case_insensitive: False, multi_line: True),
    )

  let assert [regex.Match(_, matches)] = regex.scan(re, input)
  let assert [
    Some(Ok(a_x)),
    Some(Ok(a_y)),
    Some(Ok(b_x)),
    Some(Ok(b_y)),
    Some(Ok(prize_x)),
    Some(Ok(prize_y)),
  ] =
    matches
    |> list.map(fn(it) { option.map(it, int.parse) })

  Game(prize: #(prize_x, prize_y), button_a: #(a_x, a_y), button_b: #(b_x, b_y))
}
