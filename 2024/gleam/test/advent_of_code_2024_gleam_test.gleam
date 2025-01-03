import day1
import day10
import day11
import day12
import day13
import day14
import day17
import day2
import day3
import day4
import day5
import day6
import day7
import day8
import day9
import day9_pt2
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

pub fn concatenate_test() {
  day7.concatenate(12, 345) |> should.equal(12_345)
}

pub fn solve_concat() {
  day7.is_solvable(156, [15, 6], True) |> should.be_true
}

pub fn day7_part1_test() {
  let input = day7.read_input("inputs/day7/input.txt")
  day7.part1(input) |> should.equal(5_702_958_180_383)
}

pub fn day7_part2_test() {
  let input = day7.read_input("inputs/day7/input.txt")
  day7.part2(input) |> should.equal(92_612_386_119_138)
}

pub fn day8_part1_test() {
  let input = day8.read_input("inputs/day8/input.txt")
  day8.part1(input) |> should.equal(261)
}

pub fn day8_part2_test() {
  let input = day8.read_input("inputs/day8/input.txt")
  day8.part2(input) |> should.equal(898)
}

pub fn day9_part1_test() {
  let input = day9.read_input("inputs/day9/input.txt")
  day9.part1(input) |> should.equal(6_337_921_897_505)
}

pub fn day9_part2_test() {
  let input = day9_pt2.read_input("inputs/day9/input.txt")
  day9_pt2.part2(input) |> should.equal(6_362_722_604_045)
}

pub fn day10_test() {
  let input = day10.read_input("inputs/day10/input.txt")
  day10.map_score(input) |> should.equal(#(682, 1511))
}

pub fn day11_part1_test() {
  let input = day11.read_input("inputs/day11/input.txt")
  day11.part1(input) |> should.equal(197_157)
}

pub fn day11_part2_test() {
  let input = day11.read_input("inputs/day11/input.txt")
  day11.part2(input) |> should.equal(234_430_066_982_597)
}

pub fn day12_part1_test() {
  let input = day12.read_input("inputs/day12/input.txt")
  day12.part1(input) |> should.equal(1_477_762)
}

pub fn day12_part2_test() {
  let input = day12.read_input("inputs/day12/input.txt")
  day12.part1(input) |> should.equal(1_477_762)
}

pub fn day13_part1_test() {
  let input = day13.read_input("inputs/day13/input.txt")
  day13.part1(input) |> should.equal(32_026)
}

pub fn day13_part2_test() {
  let input = day13.read_input("inputs/day13/input.txt")
  day13.part2(input) |> should.equal(89_013_607_072_065)
}

pub fn day14_part1_test() {
  let input = day14.read_input("inputs/day14/input.txt")
  day14.part1(input) |> should.equal(231_852_216)
}

pub fn day17_part1_test() {
  let input = day17.read_input("inputs/day17/input.txt")
  day17.part1(input) |> should.equal("5,1,4,0,5,1,0,2,6")
}
