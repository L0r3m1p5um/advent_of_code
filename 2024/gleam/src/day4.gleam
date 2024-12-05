import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/string
import simplifile

pub fn main() {
  let #(grid, size) = read_input("inputs/day4/input.txt")
  io.println("Part 1")
  part1(grid, size) |> io.debug
  io.println("Part 2")
  part2(grid, size) |> io.debug
}

pub type Grid =
  Dict(#(Int, Int), String)

const step_directions = [
  #(0, 1), #(0, -1), #(1, 0), #(-1, 0), #(1, 1), #(1, -1), #(-1, 1), #(-1, -1),
]

pub fn part1(grid: Grid, dimensions: #(Int, Int)) -> Int {
  indices(dimensions)
  |> list.map(test_at_index(_, grid))
  |> int.sum
}

fn indices(dimensions: #(Int, Int)) -> List(#(Int, Int)) {
  let #(rows, columns) = dimensions
  list.range(0, rows)
  |> list.map(fn(row) {
    list.range(0, columns)
    |> list.map(fn(col) { #(row, col) })
  })
  |> list.flatten
}

pub fn part2(grid: Grid, dimensions: #(Int, Int)) -> Int {
  indices(dimensions)
  |> list.count(test_x_mas_at_index(_, grid))
}

fn test_x_mas_at_index(index: #(Int, Int), grid: Grid) -> Bool {
  let check_diag = fn(step: #(Int, Int)) -> Bool {
    case
      dict.get(grid, step_index(index, step, 1)),
      dict.get(grid, step_index(index, step, -1))
    {
      Ok("M"), Ok("S") -> True
      Ok("S"), Ok("M") -> True
      _, _ -> False
    }
  }
  let letter = dict.get(grid, index)
  case letter {
    Ok("A") -> {
      check_diag(#(1, 1)) && check_diag(#(1, -1))
    }
    _ -> False
  }
}

fn test_at_index(index: #(Int, Int), grid: Grid) -> Int {
  case dict.get(grid, index) {
    Ok("X") -> {
      step_directions
      |> list.map(test_with_step(grid, index, _))
      |> list.count(fn(it) { it })
    }
    _ -> 0
  }
}

fn test_with_step(grid: Grid, from: #(Int, Int), step: #(Int, Int)) -> Bool {
  let values =
    [1, 2, 3]
    |> list.map(fn(size) {
      step_index(from, step, size)
      |> dict.get(grid, _)
    })
  case values {
    [Ok("M"), Ok("A"), Ok("S")] -> True
    _ -> False
  }
}

fn step_index(index: #(Int, Int), step: #(Int, Int), steps: Int) -> #(Int, Int) {
  let #(x1, y1) = index
  let #(x2, y2) = step
  #(x1 + { x2 * steps }, y1 + { y2 * steps })
}

pub fn read_input(filename: String) -> #(Grid, #(Int, Int)) {
  let assert Ok(content) = simplifile.read(filename)
  let lists =
    content
    |> string.split("\n")
    |> list.map(string.to_graphemes)

  let grid =
    lists
    |> list.index_map(fn(row, row_index) {
      row
      |> list.index_map(fn(letter, col_index) {
        #(#(row_index, col_index), letter)
      })
    })
    |> list.flatten
    |> dict.from_list

  let rows = list.length(lists)
  let columns = case lists {
    [x, ..] -> list.length(x)
    _ -> panic
  }
  #(grid, #(rows, columns))
}
