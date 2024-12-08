import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/set
import gleam/string
import simplifile

pub fn main() {
  let input = read_input("inputs/day8/input.txt")
  io.println("Part 1")
  part1(input) |> io.debug
  io.println("Part 2")
  part2(input) |> io.debug
}

pub fn part1(input: Map) -> Int {
  solve(input, False)
}

pub fn part2(input: Map) -> Int {
  solve(input, True)
}

pub fn solve(input: Map, is_pt2: Bool) -> Int {
  let Map(nodes, row_bound, col_bound) = input
  nodes
  |> dict.fold(set.new(), fn(acc, _, coords) {
    list.combination_pairs(coords)
    |> list.flat_map(fn(pair) {
      case is_pt2 {
        False -> find_antinodes_pt1(pair.0, pair.1)
        True -> find_antinodes_pt2(pair.0, pair.1, #(row_bound, col_bound))
      }
    })
    |> set.from_list
    |> set.union(acc)
  })
  |> set.filter(in_bounds(_, #(row_bound, col_bound)))
  |> set.size
}

fn add(x: #(Int, Int), y: #(Int, Int)) -> #(Int, Int) {
  #({ x.0 + y.0 }, { x.1 + y.1 })
}

fn sub(x: #(Int, Int), y: #(Int, Int)) -> #(Int, Int) {
  #({ x.0 - y.0 }, { x.1 - y.1 })
}

fn in_bounds(first: #(Int, Int), bound: #(Int, Int)) -> Bool {
  case first, bound {
    #(x, y), _ if x < 0 || y < 0 -> False
    #(x1, y1), #(x2, y2) if x1 > x2 || y1 > y2 -> False
    _, _ -> True
  }
}

const primes_to_53 = [
  2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53,
]

fn normalize(a: #(Int, Int)) -> #(Int, Int) {
  // We can use a limited number of primes because we know the input size
  do_normalize(a, primes_to_53)
}

fn do_normalize(a: #(Int, Int), primes: List(Int)) -> #(Int, Int) {
  case a, primes {
    a, [] -> a
    #(0, 0), _ -> #(0, 0)
    #(x, y), [prime, ..rest] -> {
      use <- bool.guard(
        { prime > int.absolute_value(x) || prime > int.absolute_value(y) },
        a,
      )
      case int.remainder(x, prime), int.remainder(y, prime) {
        Ok(0), Ok(0) -> do_normalize(#({ x / prime }, { y / prime }), primes)
        _, _ -> do_normalize(a, rest)
      }
    }
  }
}

fn find_antinodes_pt1(
  first: #(Int, Int),
  second: #(Int, Int),
) -> List(#(Int, Int)) {
  let step = sub(second, first)
  [sub(first, step), add(second, step)]
}

fn find_antinodes_pt2(
  first: #(Int, Int),
  second: #(Int, Int),
  bounds: #(Int, Int),
) -> List(#(Int, Int)) {
  let #(x, y) as step = sub(second, first) |> normalize()
  list.append(
    gen_antinodes(first, step, bounds, []),
    gen_antinodes(second, #(-x, -y), bounds, []),
  )
}

fn gen_antinodes(
  position: #(Int, Int),
  step: #(Int, Int),
  bounds: #(Int, Int),
  antinodes: List(#(Int, Int)),
) {
  let next = add(position, step)
  case in_bounds(next, bounds) {
    False -> {
      antinodes
    }
    True -> gen_antinodes(next, step, bounds, [next, ..antinodes])
  }
}

type Coord =
  #(Int, Int)

pub type Map {
  Map(nodes: Dict(String, List(Coord)), row_bound: Int, col_bound: Int)
}

type Parser {
  Parser(row: Int, col: Int, nodes: Dict(String, List(Coord)))
}

pub fn read_input(filename: String) -> Map {
  let assert Ok(content) = simplifile.read(filename)
  parse(Parser(0, 0, dict.new()), { content |> string.drop_end(1) })
}

fn add_node(parser: Parser, name: String) -> Parser {
  let Parser(row, col, nodes) = parser
  let new_nodes =
    dict.upsert(nodes, name, fn(coords) {
      case coords {
        None -> [#(row, col)]
        Some(coords) -> [#(row, col), ..coords]
      }
    })
  Parser(row, { col + 1 }, new_nodes)
}

fn advance_col(parser: Parser) -> Parser {
  let Parser(_, col, ..) = parser
  Parser(..parser, col: { col + 1 })
}

fn advance_row(parser: Parser) -> Parser {
  let Parser(row, ..) = parser
  Parser(..parser, row: { row + 1 }, col: 0)
}

fn parse(parser: Parser, input: String) -> Map {
  case string.pop_grapheme(input) {
    Ok(#(next, rest)) -> {
      let run = fn(action) { parser |> action |> parse(rest) }

      case next {
        "." -> run(advance_col(_))
        "\n" -> run(advance_row(_))
        node -> run(add_node(_, node))
      }
    }
    Error(_) -> {
      let Parser(nodes: nodes, row: row, col: col) = parser
      Map(nodes: nodes, row_bound: row, col_bound: { col - 1 })
    }
  }
}
