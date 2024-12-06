import day1
import day2
import day3
import day4
import day5
import day6
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

pub fn day1_part1_test() {
  let input = day1.read_input("inputs/day1/input.txt")
  day1.part1(input) |> should.equal(1_189_304)
}

pub fn day1_part2_test() {
  let input = day1.read_input("inputs/day1/input.txt")
  day1.part2(input) |> should.equal(24_349_736)
}

pub fn day2_part1_test() {
  let input = day2.read_input("inputs/day2/input.txt")
  day2.part1(input) |> should.equal(463)
}

pub fn day2_part2_test() {
  let input = day2.read_input("inputs/day2/input.txt")
  day2.part2(input) |> should.equal(514)
}

pub fn day3_part2_test() {
  let input = day3.read_input("inputs/day3/input.txt")
  day3.part2(input) |> should.equal(85_508_223)
}

pub fn day4_part1_test() {
  let #(grid, dimensions) = day4.read_input("inputs/day4/input.txt")
  day4.part1(grid, dimensions) |> should.equal(2642)
}

pub fn day4_part2_test() {
  let #(grid, dimensions) = day4.read_input("inputs/day4/input.txt")
  day4.part2(grid, dimensions) |> should.equal(1974)
}

pub fn day5_part1_test() {
  let #(rules, updates) = day5.read_input("inputs/day5/input.txt")
  day5.part1(rules, updates) |> should.equal(4996)
}

pub fn day5_part2_test() {
  let #(rules, updates) = day5.read_input("inputs/day5/input.txt")
  day5.part2(rules, updates) |> should.equal(6311)
}

pub fn day6_part1_test() {
  let board = day6.read_input("inputs/day6/input.txt")
  day6.part1(board) |> should.equal(5331)
}

pub fn day6_part2_test() {
  // My solution is slow on the real input
  let board = day6.read_input("inputs/day6/example.txt")
  day6.part2(board) |> should.equal(6)
}
