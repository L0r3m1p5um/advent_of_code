import day1
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

pub fn day1_part1_test() {
  let input = day1.read_input("inputs/day1.txt")
  day1.part1(input) |> should.equal(1_189_304)
}

pub fn day1_part2_test() {
  let input = day1.read_input("inputs/day1.txt")
  day1.part2(input) |> should.equal(24_349_736)
}
