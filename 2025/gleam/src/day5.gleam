import gleam/int
import gleam/io
import gleam/list
import gleam/pair
import gleam/result
import gleam/string
import simplifile

pub fn main() {
  let database = read_input("inputs/day5/input.txt")

  io.println("Part 1")
  database.ingredients |> list.count(is_fresh(_, database)) |> echo

  io.println("Part 2")
  database.ranges
  |> compress_ranges
  |> list.map(fn(range) { range.1 - range.0 + 1 })
  |> int.sum
  |> echo
}

fn is_fresh(ingredient: Int, database: Database) -> Bool {
  database.ranges
  |> list.any(fn(range) {
    let #(start, end) = range
    start <= ingredient && end >= ingredient
  })
}

fn compress_ranges(ranges: List(Range)) -> List(Range) {
  compress_ranges_inner(ranges, [])
}

fn compress_ranges_inner(ranges: List(Range), acc: List(Range)) -> List(Range) {
  case ranges {
    [] -> acc
    [range, ..rest] -> {
      let #(compressed, remaining) = compress_one(range, rest)
      compress_ranges_inner(remaining, [compressed, ..acc])
    }
  }
}

type Range =
  #(Int, Int)

fn compress_one(range: Range, ranges: List(Range)) -> #(Range, List(Range)) {
  let in_range = fn(n, r) {
    let #(s, e) = r
    { s <= n } && { e >= n }
  }
  let #(start1, end1) = range
  let #(overlapping, nonoverlapping) =
    ranges
    |> list.partition(fn(range2) {
      let #(start2, end2) = range2
      in_range(end2, range)
      || in_range(end1, range2)
      || in_range(start2, range)
      || in_range(start1, range2)
    })
  case overlapping {
    [] -> #(range, nonoverlapping)
    overlapping -> {
      let assert Ok(new_start) =
        [range, ..overlapping]
        |> list.map(pair.first)
        |> list.reduce(fn(x, y) {
          case x < y {
            True -> x
            False -> y
          }
        })
      let assert Ok(new_end) =
        [range, ..overlapping]
        |> list.map(pair.second)
        |> list.reduce(fn(x, y) {
          case x > y {
            True -> x
            False -> y
          }
        })
      compress_one(#(new_start, new_end), nonoverlapping)
    }
  }
}

type Database {
  Database(ranges: List(Range), ingredients: List(Int))
}

fn read_input(filename: String) -> Database {
  let assert Ok(file) = simplifile.read(filename)
  let assert Ok(#(range_str, ing_str)) = file |> string.split_once("\n\n")
  let assert Ok(ingredients) =
    ing_str
    |> string.split("\n")
    |> list.filter(fn(x) { x != "" })
    |> list.map(int.parse)
    |> result.all
  let ranges =
    range_str
    |> string.split("\n")
    |> list.map(fn(x) {
      let assert Ok(#(start_str, end_str)) =
        string.trim(x) |> string.split_once("-")
      let assert Ok(start) = int.parse(start_str)
      let assert Ok(end) = int.parse(end_str)
      #(start, end)
    })
  Database(ranges, ingredients)
}
