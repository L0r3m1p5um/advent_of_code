import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/set.{type Set}
import gleam/string
import pocket_watch
import simplifile

pub fn main() {
  use <- pocket_watch.simple("Day 10")
  let input = read_input("inputs/day10/input.txt")
  let #(part1, part2) = map_score(input)
  io.println("Part 1")
  io.debug(part1)
  io.println("Part 2")
  io.debug(part2)
}

pub type Map =
  Dict(#(Int, Int), Node)

pub type Node {
  Node(location: #(Int, Int), height: Int, node_type: NodeType)
}

pub type NodeType {
  Destination
  Edges(Set(#(Int, Int)))
  KnownDestinations(destinations: Set(#(Int, Int)), paths: Int)
}

pub fn map_score(map: Map) -> #(Int, Int) {
  let start_locations =
    map
    |> dict.filter(fn(_, value) { value.height == 0 })
    |> dict.keys
    |> set.from_list

  start_locations
  |> set.fold(#(#(0, 0), map), fn(acc, location) {
    let #(#(dest_total, path_total), current_map) = acc
    let #(#(dest_score, path_score), updated_map) = score(current_map, location)
    #(#({ dest_total + dest_score }, { path_total + path_score }), updated_map)
  })
  |> fn(it) { it.0 }
}

// #(count_of_destinations, number_of_paths)
fn score(map: Map, start_location: #(Int, Int)) -> #(#(Int, Int), Map) {
  let #(#(dests, paths), updated_map) = destinations(map, start_location)
  #(#(set.size(dests), paths), updated_map)
}

fn destinations(
  map: Map,
  start_location: #(Int, Int),
) -> #(#(Set(#(Int, Int)), Int), Map) {
  case dict.get(map, start_location) {
    Error(Nil) -> #(#(set.new(), 0), map)
    Ok(Node(location, _, Destination)) -> #(
      #(set.from_list([location]), 1),
      map,
    )
    Ok(Node(_, _, KnownDestinations(dests, paths))) -> #(#(dests, paths), map)
    Ok(Node(location, height, Edges(edges))) ->
      {
        use #(#(destination_acc, paths_acc), current_map), next_location <- set.fold(
          edges,
          #(#(set.new(), 0), map),
        )
        let #(#(destinations, paths), updated_map) =
          destinations(current_map, next_location)
        #(
          #(set.union(destination_acc, destinations), { paths + paths_acc }),
          updated_map,
        )
      }
      |> fn(it) {
        let #(#(destinations, paths), new_map) = it
        #(
          #(destinations, paths),
          dict.insert(
            new_map,
            location,
            Node(location, height, KnownDestinations(destinations, paths)),
          ),
        )
      }
  }
}

pub fn read_input(filename: String) -> Map {
  let assert Ok(content) = simplifile.read(filename)
  content
  |> string.trim
  |> string.split("\n")
  |> list.index_map(fn(row, row_index) {
    let assert Ok(values) =
      row
      |> string.to_graphemes
      |> list.map(int.parse)
      |> result.all
    values
    |> list.index_map(fn(column, column_index) {
      #(#(row_index, column_index), column)
    })
  })
  |> list.flatten
  |> dict.from_list
  |> grid_to_nodes
}

fn grid_to_nodes(grid: Dict(#(Int, Int), Int)) -> Map {
  grid
  |> dict.map_values(fn(location, value) {
    case value {
      9 -> Node(location, 9, Destination)
      height -> {
        let #(x, y) = location
        let adjacent =
          [#({ x + 1 }, y), #(x, { y + 1 }), #({ x - 1 }, y), #(x, { y - 1 })]
          |> list.map(fn(it) { #(it, dict.get(grid, it)) })
        let edges =
          adjacent
          |> list.filter_map(fn(it) {
            let #(coord, adjacent_height) = it
            case adjacent_height == Ok({ height + 1 }) {
              True -> Ok(coord)
              False -> Error(Nil)
            }
          })
          |> set.from_list
        Node(location, height, Edges(edges))
      }
    }
  })
}
