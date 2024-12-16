import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import pocket_watch
import simplifile
import utils

pub fn main() {
  let input = read_input("inputs/day11/input.txt")
  io.println("Part 1")
  pocket_watch.simple("Part 1", fn() { part1(input) |> io.debug })
  io.println("Part 2")
  pocket_watch.simple("Part 2", fn() { part2(input) |> io.debug })
}

pub fn part1(input: List(Int)) -> Int {
  blink(input, 25)
  |> list.length
}

pub fn part2(input: List(Int)) -> Int {
  memoized_blink(dict.new(), input, 75)
  |> fn(it) { it.0 }
}

fn blink(input: List(Int), count: Int) -> List(Int) {
  list.range(1, count)
  |> list.fold(input, fn(acc, _) {
    acc
    |> list.flat_map(update_stone)
  })
}

type Memo =
  Dict(#(Int, Int), Int)

fn memoized_blink(
  memo: Memo,
  stones: List(Int),
  iterations: Int,
) -> #(Int, Memo) {
  stones
  |> list.fold(#(0, memo), fn(acc, it) {
    let #(count, memo_acc) = acc
    use <- bool.guard({ iterations == 1 }, #(
      { count + { update_stone(it) |> list.length } },
      memo_acc,
    ))
    case dict.get(memo_acc, #(it, iterations)) {
      Ok(size) -> {
        #({ count + size }, memo)
      }
      Error(_) -> {
        let #(size, updated_memo) =
          memoized_blink(memo_acc, update_stone(it), { iterations - 1 })
        #({ count + size }, dict.insert(updated_memo, #(it, iterations), size))
      }
    }
  })
}

fn update_stone(stone: Int) -> List(Int) {
  use <- bool.guard({ stone == 0 }, [1])
  let num_digits = count_digits(stone)
  case int.remainder(num_digits, 2) == Ok(0) {
    True -> {
      let divisor = utils.power(10, { num_digits / 2 })
      let first_half = stone / divisor
      let assert Ok(second_half) = int.remainder(stone, divisor)
      [first_half, second_half]
    }
    False -> [{ 2024 * stone }]
  }
}

fn count_digits(val: Int) -> Int {
  do_count_digits(val, 1)
}

fn do_count_digits(val: Int, acc: Int) -> Int {
  let next = val / 10
  case next {
    0 -> acc
    x -> do_count_digits(x, { acc + 1 })
  }
}

pub fn read_input(filename: String) -> List(Int) {
  let assert Ok(content) = simplifile.read(filename)
  let assert Ok(stones) =
    content
    |> string.trim
    |> string.split(" ")
    |> list.map(int.parse)
    |> result.all
  stones
}
