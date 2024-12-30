import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/regex
import gleam/result
import gleam/string
import simplifile

pub fn main() {
  let input = read_input("inputs/day19/input.txt")
  io.println("Part 1")
  part1(input) |> io.debug
  io.println("Part 2")
  part2(input) |> io.debug
}

pub fn part1(input: #(List(String), List(String))) {
  let towels = input.0 |> string.join("|")
  let assert Ok(re) =
    regex.compile("^(" <> towels <> ")+$", regex.Options(False, False))
  input.1
  |> list.filter(regex.check(re, _))
  |> list.length
}

pub fn part2(input: #(List(String), List(String))) {
  let towels = input.0 |> list.group(string.length)
  input.1
  |> list.map(solve_pattern(towels, _))
  |> int.sum
}

fn solve_pattern(towels: Dict(Int, List(String)), pattern: String) -> Int {
  let combo_dict =
    list.range(1, string.length(pattern))
    |> list.fold(dict.from_list([#(0, 1)]), fn(acc, current_len) {
      let combinations =
        list.range(0, current_len - 1)
        |> list.map(fn(previous_len) {
          {
            use previous_combinations <- result.try(dict.get(acc, previous_len))
            use candidates <- result.map(dict.get(
              towels,
              current_len - previous_len,
            ))
            previous_combinations
            * count_matches(
              string.drop_start(pattern, previous_len),
              candidates,
            )
          }
          |> result.unwrap(0)
        })
        |> int.sum
      dict.insert(acc, current_len, combinations)
    })

  dict.get(combo_dict, string.length(pattern))
  |> result.unwrap(0)
}

fn count_matches(pattern: String, to_match: List(String)) -> Int {
  to_match
  |> list.count(fn(it) { string.starts_with(pattern, it) })
}

pub fn read_input(filename: String) -> #(List(String), List(String)) {
  let assert Ok(content) = simplifile.read(filename)

  let assert Ok(#(towels, patterns)) = string.split_once(content, "\n\n")
  let towels = towels |> string.trim |> string.split(", ")
  let patterns = patterns |> string.trim |> string.split("\n")
  #(towels, patterns)
}
