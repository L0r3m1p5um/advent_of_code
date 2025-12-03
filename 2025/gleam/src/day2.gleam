import gleam/int
import gleam/io
import gleam/list
import gleam/string
import gleam/yielder.{type Yielder, Done, Next}
import simplifile

pub fn main() {
  let ranges = read_input("inputs/day2/input.txt")

  io.println("Part 1")
  part1(ranges) |> echo

  io.println("Part 2")
  part2(ranges) |> echo
}

fn part1(ranges) -> Int {
  generator()
  |> yielder.map(check_number(_, ranges))
  |> yielder.take_while(fn(x) { x != AboveRange })
  |> yielder.fold(0, fn(acc, result) {
    case result {
      InRange(x) -> acc + x
      _ -> acc
    }
  })
}

fn part2(ranges: Ranges) -> Int {
  generator2(ranges.max)
  |> list.map(check_number(_, ranges))
  |> list.fold(0, fn(acc, result) {
    case result {
      InRange(x) -> acc + x
      _ -> acc
    }
  })
}

fn generator() -> Yielder(Int) {
  yielder.unfold(#(1, 1), fn(x) {
    let #(num, digits) = x
    let next_num = num + 1
    let next_digits = case next_num / power(10, digits) {
      0 -> digits
      _ -> digits + 1
    }
    Next({ num * power(10, digits) } + num, #(next_num, next_digits))
  })
}

fn generator2(max: Int) -> List(Int) {
  yielder.unfold(#(1, 1), fn(x) {
    let #(num, digits) = x
    let next_num = num + 1
    let next_digits = case next_num / power(10, digits) {
      0 -> digits
      _ -> digits + 1
    }
    let duplicates =
      yielder.iterate(2, fn(x) { x + 1 })
      |> yielder.map(duplicate_number(num, digits, _, 0))
      |> yielder.take_while(fn(x) { x <= max })
      |> yielder.to_list
    case duplicates {
      [] -> Done
      _ -> Next(duplicates, #(next_num, next_digits))
    }
  })
  |> yielder.to_list
  |> list.flatten
  |> list.unique
}

fn duplicate_number(num: Int, digits: Int, times: Int, acc: Int) -> Int {
  case times {
    0 -> acc
    _ ->
      duplicate_number(
        num,
        digits,
        times - 1,
        { acc * power(10, digits) } + num,
      )
  }
}

fn check_number(num: Int, ranges: Ranges) -> CheckResult {
  let Ranges(range_list, max) = ranges
  case num > max {
    True -> AboveRange
    False ->
      range_list
      |> list.any(fn(range) {
        let #(start, end) = range
        num >= start && num <= end
      })
      |> fn(result) {
        case result {
          True -> InRange(num)
          False -> NotInRange
        }
      }
  }
}

type Ranges {
  Ranges(ranges: List(#(Int, Int)), max: Int)
}

type CheckResult {
  InRange(Int)
  NotInRange
  AboveRange
}

fn power(n: Int, exponent: Int) -> Int {
  power_inner(n, exponent, 1)
}

fn power_inner(n: Int, exponent: Int, acc: Int) -> Int {
  case exponent {
    0 -> acc
    x if x < 0 -> panic
    x -> power_inner(n, x - 1, acc * n)
  }
}

fn read_input(filename: String) -> Ranges {
  let assert Ok(file) = simplifile.read(filename)
  let range_list =
    file
    |> string.split(",")
    |> list.map(fn(x) {
      let assert Ok(#(start_str, end_str)) =
        string.trim(x) |> string.split_once("-")
      let assert Ok(start) = int.parse(start_str)
      let assert Ok(end) = int.parse(end_str)
      #(start, end)
    })
  let max =
    range_list
    |> list.map(fn(x) { x.1 })
    |> list.fold(0, fn(acc, it) { int.max(acc, it) })
  Ranges(range_list, max)
}
