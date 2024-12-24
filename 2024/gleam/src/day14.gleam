import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/regex
import gleam/string
import parallel_map
import simplifile

pub fn main() {
  let input = read_input("inputs/day14/input.txt")
  io.println("Part 1")
  part1(input) |> io.debug
}

pub fn part1(input: List(Robot)) {
  let size = #(101, 103)
  input
  |> list.map(move(_, 100, size))
  |> score(size)
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

fn display(robots: List(Robot), dimensions: #(Int, Int)) {
  let map =
    robots
    |> list.fold(dict.new(), fn(acc, robot) {
      dict.upsert(acc, robot.position, fn(it) {
        case it {
          Some(count) -> count + 1
          None -> 1
        }
      })
    })

  use y <- list.each(list.range(0, { dimensions.1 - 1 }))
  use x <- list.each(list.range(0, { dimensions.0 - 1 }))
  case dict.get(map, #(x, y)) {
    Ok(count) -> io.print(int.to_string(count))
    Error(_) -> io.print(".")
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
