import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

pub fn main() {
  let input = read_input("inputs/day1.txt")

  io.println("Part 1")
  part1(input) |> io.debug

  io.println("Part 2")
  part2(input) |> io.debug
}

pub fn part1(input: #(List(Int), List(Int))) -> Int {
  let #(list1, list2) = input
  let sorted1 = list1 |> list.sort(int.compare)
  let sorted2 = list2 |> list.sort(int.compare)
  list.zip(sorted1, sorted2)
  |> list.map(fn(it) {
    let #(a, b) = it
    case a < b {
      True -> b - a
      False -> a - b
    }
  })
  |> int.sum
  |> io.debug
}

pub fn part2(input: #(List(Int), List(Int))) -> Int {
  let #(list1, list2) = input
  let frequencies = frequency_map(list2)
  list1
  |> list.map(fn(it) {
    let count = dict.get(frequencies, it) |> result.unwrap(0)
    it * count
  })
  |> int.sum
}

fn frequency_map(input: List(Int)) -> Dict(Int, Int) {
  input
  |> list.fold(dict.new(), fn(acc, it) {
    case dict.get(acc, it) {
      Ok(count) -> dict.insert(acc, it, { count + 1 })
      _ -> dict.insert(acc, it, 1)
    }
  })
}

pub fn read_input(filename: String) -> #(List(Int), List(Int)) {
  let assert Ok(input) = simplifile.read(from: filename)
  input
  // Drop the last newline before the end of the file
  |> string.drop_end(1)
  |> string.split("\n")
  |> list.map(fn(row) {
    string.split(row, "   ")
    |> fn(it) {
      let assert [Ok(fst), Ok(snd)] = it |> list.map(int.parse)
      #(fst, snd)
    }
  })
  |> list.reverse
  |> list.fold(#([], []), fn(acc, it) { #([it.0, ..acc.0], [it.1, ..acc.1]) })
}
