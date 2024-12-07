import gleam/bool
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

pub fn main() {
  let input = read_input("inputs/day7/input.txt")
  io.println("Part 1")
  part1(input) |> io.debug
  io.println("Part 2")
  part2(input) |> io.debug
}

pub fn part1(input: List(#(Int, List(Int)))) -> Int {
  input
  |> list.filter(fn(it) { is_solvable(it.0, it.1, False) })
  |> list.fold(0, fn(acc, it) { it.0 + acc })
}

pub fn part2(input: List(#(Int, List(Int)))) -> Int {
  input
  |> list.filter(fn(it) { is_solvable(it.0, it.1, True) })
  |> list.fold(0, fn(acc, it) { it.0 + acc })
}

pub fn is_solvable(target: Int, args: List(Int), with_concat: Bool) -> Bool {
  let do_ops = case with_concat {
    True -> fn(arg: Int, current: Int) -> List(Int) {
      [arg + current, arg * current, concatenate(current, arg)]
    }
    False -> fn(arg: Int, current: Int) -> List(Int) {
      [arg + current, arg * current]
    }
  }

  let assert [first, ..rest] = args
  list.fold(rest, [first], fn(acc, arg) {
    acc
    |> list.flat_map(fn(total) {
      do_ops(arg, total) |> list.filter(fn(x) { x <= target })
    })
  })
  |> list.filter(fn(it) { it == target })
  |> list.is_empty
  |> bool.negate
}

pub fn concatenate(x: Int, y: Int) -> Int {
  let pow = count_digits(y, 1)
  { x * power(10, pow) } + y
}

fn power(x: Int, pow: Int) -> Int {
  do_power(x, pow, x)
}

fn do_power(x: Int, pow: Int, acc: Int) -> Int {
  case pow <= 1 {
    True -> acc
    False -> do_power(x, { pow - 1 }, acc * x)
  }
}

fn count_digits(x: Int, digits: Int) -> Int {
  let y = x / 10
  case y == 0 {
    True -> digits
    False -> count_digits(y, { digits + 1 })
  }
}

pub fn read_input(filename: String) -> List(#(Int, List(Int))) {
  let assert Ok(content) = simplifile.read(filename)
  content
  |> string.drop_end(1)
  |> string.split("\n")
  |> list.map(fn(line) {
    let assert Ok(#(resstr, numstr)) =
      line
      |> string.split_once(":")
    let assert Ok(nums) =
      numstr
      |> string.trim
      |> string.split(" ")
      |> list.map(int.parse)
      |> result.all
    let assert Ok(res) = int.parse(resstr)
    #(res, nums)
  })
}
