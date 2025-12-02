import gleam/int
import gleam/io
import gleam/list
import gleam/string
import simplifile

pub fn main() {
  let input = read_input("inputs/day1/input.txt")

  io.println("Part 1")
  part1(input) |> echo

  io.println("Part 2")
  part2(input) |> echo
}

fn part1(input) -> Int {
  let #(_, result) =
    input
    |> list.fold(#(50, 0), fn(acc, instruction) {
      let #(dial, count) = acc
      let new_val = case instruction {
        #(Left, amount) -> { dial - amount } % 100
        #(Right, amount) -> { dial + amount } % 100
      }
      #(new_val, case new_val {
        0 -> count + 1
        _ -> count
      })
    })
  result
}

fn part2(input) -> Int {
  let #(_, result) =
    input
    |> list.fold(#(50, 0), fn(acc, instruction) {
      let #(old_val, count) = acc
      let #(dir, amount) = instruction
      let full_rotations = amount / 100
      let partial_rotation = amount % 100
      let new_val = case dir {
        Left -> { 100 + old_val - partial_rotation } % 100
        Right -> { old_val + partial_rotation } % 100
      }
      let extra = case old_val, new_val, dir {
        // The partial rotation is less than 100, so it can't cross from 0
        0, _, _ -> 0
        _, 0, _ -> 1
        old, new, Right if old > new -> 1
        old, new, Left if new > old -> 1
        _, _, _ -> 0
      }
      #(new_val, count + full_rotations + extra)
    })
  result
}

pub type Direction {
  Left
  Right
}

pub fn read_input(filename: String) -> List(#(Direction, Int)) {
  let assert Ok(file) = simplifile.read(filename)
  file
  |> string.split("\n")
  |> list.filter(fn(x) { !string.is_empty(x) })
  |> list.map(fn(line) {
    let #(dir, rest) = case line {
      "L" <> rest -> #(Left, rest)
      "R" <> rest -> #(Right, rest)
      _ -> panic
    }
    let assert Ok(num) = int.parse(rest)
    #(dir, num)
  })
}
