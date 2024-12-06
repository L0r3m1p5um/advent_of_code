import gleam/dict.{type Dict}
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/set.{type Set}
import gleam/string
import simplifile

pub fn main() {
  let input = read_input("inputs/day6/input.txt")
  io.println("Part 1")
  part1(input) |> io.debug
  io.println("Part 2")
  part2(input) |> io.debug
}

type Coord =
  #(Int, Int)

pub type Space {
  Clear
  Blocked
}

pub type Direction {
  Up
  Down
  Right
  Left
}

pub type Guard {
  Guard(position: Coord, direction: Direction)
}

pub type Board {
  Board(
    map: Dict(Coord, Space),
    guard: Guard,
    history: Set(Guard),
    state: BoardState,
  )
}

pub type BoardState {
  Normal
  Finished
  Cycle
}

pub fn part1(input: Board) -> Int {
  let complete = run_board(input)
  complete.history
  |> set.map(fn(guard) { guard.position })
  |> set.size
}

pub fn part2(input: Board) -> Int {
  let check_cycle = fn(board) {
    case run_board(board) {
      Board(state: Cycle, ..) -> True
      _ -> False
    }
  }

  let candidates =
    input.map
    |> dict.filter(fn(_, space) {
      case space {
        Clear -> True
        _ -> False
      }
    })
    |> dict.keys

  candidates
  |> list.filter(fn(position) {
    let map = input.map |> dict.insert(position, Blocked)
    check_cycle(Board(..input, map: map))
  })
  |> list.length
}

fn run_board(board: Board) -> Board {
  case next_space(board) {
    Ok(#(_, Blocked)) -> run_board(Board(..board, guard: turn(board.guard)))
    Ok(#(coord, Clear)) -> {
      let Board(map, Guard(_, direction), history, state) = board
      let guard = Guard(coord, direction)
      case set.contains(history, guard) {
        True -> Board(map, guard, history, Cycle)
        False -> run_board(Board(map, guard, set.insert(history, guard), state))
      }
    }
    Error(_) -> Board(..board, state: Finished)
  }
}

fn next_space(board: Board) -> Result(#(Coord, Space), Nil) {
  let Board(map, Guard(#(row, col), direction), _, _) = board
  let next = case direction {
    Up -> #({ row - 1 }, col)
    Down -> #({ row + 1 }, col)
    Left -> #(row, { col - 1 })
    Right -> #(row, { col + 1 })
  }
  dict.get(map, next) |> result.map(fn(it) { #(next, it) })
}

fn turn(guard: Guard) -> Guard {
  case guard.direction {
    Up -> Right
    Right -> Down
    Down -> Left
    Left -> Up
  }
  |> Guard(guard.position, _)
}

pub fn read_input(filename: String) -> Board {
  let assert Ok(content) = simplifile.read(filename)
  parse(Parser(0, 0, dict.new(), None), content)
}

type Parser {
  Parser(row: Int, col: Int, map: Dict(Coord, Space), guard: Option(Guard))
}

fn to_board(parser: Parser) -> Board {
  let assert Some(guard) = parser.guard
  Board(parser.map, guard, set.insert(set.new(), guard), Normal)
}

fn insert(parser: Parser, space: Space) -> Parser {
  let Parser(row, col, map, guard) = parser
  let new_map = dict.insert(map, #(row, col), space)
  Parser(row, { col + 1 }, new_map, guard)
}

fn insert_guard(parser: Parser, direction: Direction) -> Parser {
  Parser(
    ..insert(parser, Clear),
    guard: Some(Guard(#(parser.row, parser.col), direction)),
  )
}

fn parse(parser: Parser, input: String) -> Board {
  case string.pop_grapheme(input) {
    Ok(#(next, rest)) -> {
      let run = fn(action) { parser |> action |> parse(rest) }

      case next {
        "." -> run(insert(_, Clear))
        "#" -> run(insert(_, Blocked))
        ">" -> run(insert_guard(_, Right))
        "<" -> run(insert_guard(_, Left))
        "v" -> run(insert_guard(_, Down))
        "^" -> run(insert_guard(_, Up))
        "\n" -> run(fn(it) { Parser(..it, row: { it.row + 1 }, col: 0) })
        _ -> panic
      }
    }
    Error(_) -> to_board(parser)
  }
}
