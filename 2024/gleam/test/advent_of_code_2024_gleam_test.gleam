import day1
import day2
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
