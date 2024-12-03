import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import simplifile

pub fn main() {
  let input = read_input("inputs/day2/input.txt")
  io.println("Part 1")
  part1(input) |> io.debug
  io.println("Part 2")
  part2(input) |> io.debug
}

type Report =
  List(Int)

type SafetyState {
  New
  Started(current: Int)
  Increasing(current: Int)
  Decreasing(current: Int)
  Unsafe
}

pub fn part1(input: List(Report)) -> Int {
  input
  |> list.map(safety_check(_, None))
  |> list.count(fn(x) { x })
}

pub fn part2(input: List(Report)) -> Int {
  input
  |> list.map(fn(report) {
    let range = list.range(0, list.length(report))
    range
    |> list.find(fn(index) { safety_check(report, Some(index)) })
    |> result.is_ok
  })
  |> list.count(fn(x) { x })
}

pub fn safety_check(report: Report, dampened_index: Option(Int)) -> Bool {
  let safety =
    report
    |> list.index_fold(New, fn(acc, it, index) {
      case index, dampened_index {
        index, Some(dampened) if index == dampened -> acc
        _, _ -> check_next(acc, it)
      }
    })
  case safety {
    Unsafe -> False
    _ -> True
  }
}

fn check_next(state: SafetyState, next: Int) -> SafetyState {
  case state {
    New -> Started(next)
    Started(current) ->
      case distance(current, next) {
        WithinInc -> Increasing(next)
        WithinDec -> Decreasing(next)
        _ -> Unsafe
      }
    Increasing(current) ->
      case distance(current, next) {
        WithinInc -> Increasing(next)
        _ -> Unsafe
      }
    Decreasing(current) ->
      case distance(current, next) {
        WithinDec -> Decreasing(next)
        _ -> Unsafe
      }
    _ -> Unsafe
  }
}

type Distance {
  OutOfRange
  WithinInc
  WithinDec
}

fn distance(start: Int, end: Int) -> Distance {
  case start - end {
    dist if dist > 0 && dist <= 3 -> WithinDec
    dist if dist < 0 && dist >= -3 -> WithinInc
    _ -> OutOfRange
  }
}

pub fn read_input(filename: String) -> List(Report) {
  let assert Ok(content) = simplifile.read(filename)
  content
  |> string.drop_end(1)
  |> string.split("\n")
  |> list.map(parse_row)
}

fn parse_row(row: String) -> Report {
  let assert Ok(report) =
    row
    |> string.split(" ")
    |> list.map(int.parse)
    |> result.all
  report
}
