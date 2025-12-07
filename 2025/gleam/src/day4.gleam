import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import simplifile

pub fn main() {
  let input = read_input("inputs/day4/input.txt")

  io.println("Part 1")
  input
  |> dict.keys
  |> list.map(count_adjacent(_, input))
  |> list.count(fn(adjacent) { adjacent < 4 })
  |> echo

  io.println("Part 2")
  part2(input) |> echo
}

type Grid =
  Dict(#(Int, Int), Int)

fn part2(grid: Grid) -> Int {
  let initial_size = dict.size(grid)
  let final = take_all(grid, initial_size)
  initial_size - dict.size(final)
}

fn take_all(grid: Grid, size: Int) -> Grid {
  let filtered =
    grid
    |> dict.map_values(fn(key, _) { key |> count_adjacent(grid) })
    |> dict.filter(fn(_, adj) { adj >= 4 })
  case filtered |> dict.size {
    new_size if size == new_size -> grid
    new_size -> take_all(filtered, new_size)
  }
}

fn count_adjacent(location: #(Int, Int), grid: Grid) {
  let #(x, y) = location
  [
    #(x + 1, y),
    #(x - 1, y),
    #(x, y + 1),
    #(x, y - 1),
    #(x + 1, y + 1),
    #(x - 1, y + 1),
    #(x + 1, y - 1),
    #(x - 1, y - 1),
  ]
  |> list.count(fn(x) { dict.get(grid, x) |> result.is_ok })
}

fn read_input(filename: String) -> Grid {
  let assert Ok(file) = simplifile.read(filename)
  let grid =
    file
    |> string.split("\n")
    |> list.filter(fn(x) { x != "" })
    |> list.map(fn(row) {
      row
      |> string.to_graphemes
      |> list.map(fn(it) {
        case it {
          "@" -> Some(Nil)
          _ -> None
        }
      })
    })
  grid
  |> list.index_fold(dict.new(), fn(acc, row, row_idx) {
    row
    |> list.index_fold(acc, fn(acc2, space, col_idx) {
      case space {
        Some(_) -> acc2 |> dict.insert(#(row_idx, col_idx), 0)
        _ -> acc2
      }
    })
  })
}
