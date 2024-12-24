import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/pair
import gleam/regex
import gleam/set
import gleam/string
import parallel_map
import simplifile

pub fn main() {
  let input = read_input("inputs/day14/input.txt")
  io.println("Part 1")
  // part1(input) |> io.debug
  io.println("Part 2")
  part2(input)
}

pub fn part1(input: List(Robot)) {
  let size = #(101, 103)
  input
  |> list.map(move(_, 100, size))
  |> score(size)
}

pub fn part2(input: List(Robot)) {
  let size = #(101, 103)
  let #(robots, steps) = find_tree(input, size, 0)
  io.println("Steps " <> int.to_string(steps))
  robots |> display(size)
}

fn move(robot: Robot, seconds: Int, dimensions: #(Int, Int)) -> Robot {
  let Robot(#(x_pos, y_pos), #(x_vel, y_vel)) = robot
  let assert Ok(new_x) =
    int.modulo({ x_pos + { x_vel * seconds } }, dimensions.0)
  let assert Ok(new_y) =
    int.modulo({ y_pos + { y_vel * seconds } }, dimensions.1)
  Robot(#(new_x, new_y), robot.velocity)
}

type Score {
  Score(q1: Int, q2: Int, q3: Int, q4: Int)
}

type Quadrant {
  Q1
  Q2
  Q3
  Q4
  Center
}

fn increment_score(score: Score, quadrant: Quadrant) -> Score {
  let Score(q1, q2, q3, q4) = score
  case quadrant {
    Q1 -> Score(..score, q1: { q1 + 1 })
    Q2 -> Score(..score, q2: { q2 + 1 })
    Q3 -> Score(..score, q3: { q3 + 1 })
    Q4 -> Score(..score, q4: { q4 + 1 })
    Center -> score
  }
}

fn score(robots: List(Robot), dimensions: #(Int, Int)) -> Int {
  let x_line = dimensions.0 / 2
  let y_line = dimensions.1 / 2
  io.println("x line " <> int.to_string(x_line))
  io.println("y line " <> int.to_string(y_line))
  robots
  |> list.fold(Score(0, 0, 0, 0), fn(acc, it) {
    case it.position {
      #(x, y) if x < x_line && y < y_line -> Q1
      #(x, y) if x < x_line && y > y_line -> Q2
      #(x, y) if x > x_line && y < y_line -> Q3
      #(x, y) if x > x_line && y > y_line -> Q4
      _ -> Center
    }
    |> increment_score(acc, _)
  })
  |> fn(it) {
    let Score(q1, q2, q3, q4) = it
    q1 * q2 * q3 * q4
  }
}

pub type Robot {
  Robot(position: #(Int, Int), velocity: #(Int, Int))
}

fn find_tree(
  robots: List(Robot),
  dimensions: #(Int, Int),
  total_steps: Int,
) -> #(List(Robot), Int) {
  case is_tree(robots, dimensions) {
    True -> #(robots, total_steps)
    False ->
      find_tree(
        { robots |> list.map(move(_, 1, dimensions)) },
        dimensions,
        total_steps + 1,
      )
  }
}

fn is_tree(robots: List(Robot), dimensions: #(Int, Int)) -> Bool {
  let positions =
    robots
    |> list.map(fn(it) { it.position })
    |> set.from_list
  let most_consecutive =
    all_coordinates(dimensions)
    |> list.fold(#(0, 0), fn(acc, it) {
      let #(current, max) = acc
      case set.contains(positions, it) {
        True if current + 1 > max -> #(current + 1, current + 1)
        True -> #(current + 1, max)
        False -> #(0, max)
      }
    })
    |> pair.second
  most_consecutive >= 10
}

fn all_coordinates(dimensions: #(Int, Int)) -> List(#(Int, Int)) {
  use x <- list.flat_map(list.range(0, dimensions.0))
  use y <- list.map(list.range(0, dimensions.1))
  #(x, y)
}

fn display(robots: List(Robot), dimensions: #(Int, Int)) {
  let positions = robots |> list.map(fn(it) { it.position }) |> set.from_list
  use y <- list.each(list.range(0, { dimensions.1 - 1 }))
  use x <- list.each(list.range(0, { dimensions.0 - 1 }))
  case set.contains(positions, #(x, y)) {
    True -> io.print("#")
    False -> io.print(".")
  }
  case x == dimensions.0 - 1 {
    True -> io.print("\n")
    False -> Nil
  }
}

pub fn read_input(filename: String) -> List(Robot) {
  let assert Ok(content) = simplifile.read(filename)
  content
  |> string.trim
  |> string.split("\n")
  |> list.map(parse_row)
}

fn parse_row(row: String) -> Robot {
  let assert Ok(re) =
    regex.compile(
      "p=(\\d+),(\\d+) v=(-?\\d+),(-?\\d+)",
      regex.Options(multi_line: False, case_insensitive: False),
    )
  let assert Ok(robot) =
    regex.scan(re, row)
    |> list.map(fn(it) {
      let assert [Some(pos_x), Some(pos_y), Some(vel_x), Some(vel_y)] =
        it.submatches
        |> list.map(fn(match) {
          option.map(match, fn(x) { int.parse(x) |> option.from_result })
          |> option.flatten
        })
      Robot(#(pos_x, pos_y), #(vel_x, vel_y))
    })
    |> list.first
  robot
}
