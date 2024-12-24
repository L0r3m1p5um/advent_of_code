import gleam/dict.{type Dict}
import gleam/io
import gleam/iterator.{type Iterator}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import simplifile

pub fn main() {
  let #(room, moves) = read_input("inputs/day15/input.txt")
  io.println("Part 1")
  part1(room, moves) |> io.debug
}

pub fn part1(room: Room, moves: List(Direction)) -> Int {
  moves
  |> list.fold(room, move)
  |> score
}

pub type Tile {
  Wall
  Box
  Empty
}

pub type Room {
  Room(tiles: Dict(#(Int, Int), Tile), robot: #(Int, Int))
}

pub type Direction {
  Up
  Down
  Left
  Right
}

type MoveResult {
  Blocked
  Clear
  PushBox(#(Int, Int))
}

fn move(room: Room, direction: Direction) -> Room {
  let Room(tiles, robot) = room
  case can_move(room, direction) {
    Blocked -> room
    Clear -> {
      Room(..room, robot: next_tile(robot, direction))
    }
    PushBox(box_position) -> {
      let next = next_tile(robot, direction)
      let new_tiles =
        tiles
        |> dict.insert(next, Empty)
        |> dict.insert(box_position, Box)
      Room(new_tiles, next)
    }
  }
}

fn can_move(room: Room, direction: Direction) -> MoveResult {
  let next = next_tile(room.robot, direction)
  case dict.get(room.tiles, next) {
    Ok(Empty) -> Clear
    Ok(Wall) -> Blocked
    Ok(Box) -> {
      let assert Ok(result) =
        path(direction, next)
        |> iterator.find_map(fn(tile) {
          case dict.get(room.tiles, tile) {
            Ok(Wall) -> Ok(Blocked)
            Ok(Empty) -> Ok(PushBox(tile))
            Ok(Box) -> Error(Nil)
            err -> {
              io.println("Reached invalid tile in path")
              io.debug(tile)
              io.debug(err)
              panic
            }
          }
        })
      result
    }
    err -> {
      io.println("Couldn't find next tile")
      io.debug(err)
      panic
    }
  }
}

fn score(room: Room) -> Int {
  room.tiles
  |> dict.filter(fn(k, v) { v == Box })
  |> dict.keys
  |> list.fold(0, fn(sum, pos) { sum + { 100 * pos.0 + pos.1 } })
}

fn path(direction: Direction, start: #(Int, Int)) -> Iterator(#(Int, Int)) {
  let next_fn = case direction {
    Up -> fn(pos: #(Int, Int)) { #(pos.0 - 1, pos.1) }
    Down -> fn(pos: #(Int, Int)) { #(pos.0 + 1, pos.1) }
    Left -> fn(pos: #(Int, Int)) { #(pos.0, pos.1 - 1) }
    Right -> fn(pos: #(Int, Int)) { #(pos.0, pos.1 + 1) }
  }
  iterator.iterate(start, next_fn)
}

fn next_tile(current: #(Int, Int), direction: Direction) -> #(Int, Int) {
  let #(x, y) = current
  case direction {
    Up -> #(x - 1, y)
    Down -> #(x + 1, y)
    Left -> #(x, y - 1)
    Right -> #(x, y + 1)
  }
}

pub fn read_input(filename: String) -> #(Room, List(Direction)) {
  let assert Ok(input) = simplifile.read(filename)
  let assert Ok(#(room, directions)) = string.split_once(input, "\n\n")
  #(parse_room(room), parse_directions(directions))
}

fn parse_room(input: String) -> Room {
  let rows = input |> string.trim |> string.split("\n")
  let assert #(tiles, Some(robot)) =
    rows
    |> list.index_fold(#(dict.new(), None), fn(acc, row, row_idx) {
      row
      |> string.to_graphemes
      |> list.index_fold(acc, fn(acc2, col, col_idx) {
        let #(t, r) = acc2
        case col {
          "#" -> #(dict.insert(t, #(row_idx, col_idx), Wall), r)
          "." -> #(dict.insert(t, #(row_idx, col_idx), Empty), r)
          "O" -> #(dict.insert(t, #(row_idx, col_idx), Box), r)
          "@" -> #(
            dict.insert(t, #(row_idx, col_idx), Empty),
            Some(#(row_idx, col_idx)),
          )
          x -> {
            io.println("invalid tile " <> x)
            panic
          }
        }
      })
    })
  Room(tiles, robot)
}

fn parse_directions(input: String) -> List(Direction) {
  input
  |> string.to_graphemes
  |> list.filter(fn(it) { it != "\n" })
  |> list.map(fn(dir) {
    case dir {
      "<" -> Left
      ">" -> Right
      "^" -> Up
      "v" -> Down
      x -> {
        io.println("Invalid direction " <> x)
        panic
      }
    }
  })
}
