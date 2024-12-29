import dijkstra
import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/set.{type Set}
import gleam/string
import simplifile

pub fn main() {
  let input = read_input("inputs/day18/input.txt")
  io.println("Part 1")
  part1(input) |> io.debug
  io.println("Part 2")
  part2(input) |> io.debug
}

pub type Tile {
  Clear
  Corrupt
}

pub fn part1(input) -> Int {
  let size = 71
  let map = build_map(input, size, 1024)
  draw_map(map, size)
  let assert Ok(solution) =
    dijkstra.shortest_path(
      nodes: map,
      start: #(0, 0),
      get_keys: dict.keys,
      is_end: fn(key) { key == #(size - 1, size - 1) },
      find_neighbors: find_neighbors,
    )
  solution
}

pub fn part2(input) {
  let size = 71
  let index =
    bisect(1, list.length(input), fn(test_val) {
      let map = build_map(input, size, test_val)
      dijkstra.shortest_path(
        nodes: map,
        start: #(0, 0),
        get_keys: dict.keys,
        is_end: fn(key) { key == #(size - 1, size - 1) },
        find_neighbors: find_neighbors,
      )
      |> result.is_ok
    })
  input
  |> list.drop(index)
  |> list.first
  |> result.map(fn(it) { #(it.1, it.0) })
}

fn bisect(good: Int, bad: Int, test_func: fn(Int) -> Bool) -> Int {
  use <- bool.guard(good == bad - 1, good)
  let next = good + { { bad - good } / 2 }
  case test_func(next) {
    True -> bisect(next, bad, test_func)
    False -> bisect(good, next, test_func)
  }
}

fn find_neighbors(
  map: Dict(#(Int, Int), Tile),
  node: #(Int, Int),
) -> Set(#(#(Int, Int), Int)) {
  case dict.get(map, node) {
    Ok(Corrupt) -> set.new()
    Ok(Clear) -> {
      let #(x, y) = node
      let adjacent =
        [#(x + 1, y), #(x - 1, y), #(x, y + 1), #(x, y - 1)]
        |> list.map(fn(it) {
          dict.get(map, it) |> result.map(fn(tile) { #(it, tile) })
        })
        |> result.values
      adjacent
      |> list.filter(fn(it) { it.1 == Clear })
      |> list.map(fn(it) { #(it.0, 1) })
      |> set.from_list
    }
    _ -> panic as "Node not in dictionary"
  }
}

fn draw_map(map: Dict(#(Int, Int), Tile), size: Int) -> Nil {
  list.range(0, size - 1)
  |> list.each(fn(row) {
    list.range(0, size)
    |> list.each(fn(col) {
      case dict.get(map, #(row, col)) {
        Ok(Clear) -> io.print(".")
        Ok(Corrupt) -> io.print("#")
        _ -> io.print("\n")
      }
    })
  })
}

fn build_map(
  input: List(#(Int, Int)),
  size: Int,
  bytes: Int,
) -> Dict(#(Int, Int), Tile) {
  let map =
    all_coords(size)
    |> list.fold(dict.new(), fn(acc, it) { dict.insert(acc, it, Clear) })
  input
  |> list.take(bytes)
  |> list.fold(map, fn(acc, it) { dict.insert(acc, it, Corrupt) })
}

fn all_coords(size: Int) -> List(#(Int, Int)) {
  list.range(0, size - 1)
  |> list.flat_map(fn(row) {
    list.range(0, size - 1)
    |> list.map(fn(col) { #(row, col) })
  })
}

pub fn read_input(filename: String) -> List(#(Int, Int)) {
  let assert Ok(content) = simplifile.read(filename)
  content
  |> string.trim
  |> string.split("\n")
  |> list.map(fn(it) {
    let assert Ok([y, x]) =
      it
      |> string.split(",")
      |> list.map(int.parse)
      |> result.all
    #(x, y)
  })
}
