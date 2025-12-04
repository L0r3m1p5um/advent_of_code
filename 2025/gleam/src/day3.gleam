import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

pub fn main() {
  let input = read_input("inputs/day3/input.txt")

  io.println("Part 1")
  input
  |> list.map(calculate_joltage(_, 2))
  |> int.sum
  |> echo

  io.println("Part 2")
  input
  |> list.map(calculate_joltage(_, 12))
  |> int.sum
  |> echo
}

fn calculate_joltage(bank: List(Int), batteries: Int) -> Int {
  calculate_joltage_inner(bank, batteries, 0)
}

fn calculate_joltage_inner(bank: List(Int), batteries: Int, acc: Int) -> Int {
  // Returns the maximum value and its index. If there are multiple maximum
  // values, it returns the first occurrence.
  let max = list.index_fold(_, #(0, 0), fn(acc, x, index) {
    let #(current_max, _) = acc
    case x > current_max {
      True -> #(x, index)
      False -> acc
    }
  })

  case batteries {
    0 -> acc
    _ -> {
      let length = bank |> list.length
      let #(digit, index) =
        bank
        // Need to reserve some of the list for the rest of the batteries
        |> list.take(length - { batteries - 1 })
        |> max
      calculate_joltage_inner(
        // Head of the list will start where we took the current digit
        bank |> list.drop(index + 1),
        batteries - 1,
        { 10 * acc } + digit,
      )
    }
  }
}

fn read_input(filename: String) -> List(List(Int)) {
  let assert Ok(file) = simplifile.read(filename)
  file
  |> string.split("\n")
  |> list.filter(fn(x) { x != "" })
  |> list.map(fn(line) {
    let assert Ok(joltages) =
      line
      |> string.to_graphemes
      |> list.map(int.parse)
      |> result.all
    joltages
  })
}
