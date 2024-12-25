import gleam/bool
import gleam/dict.{type Dict}
import gleam/io
import gleam/iterator.{type Iterator, type Step, Done, Next}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/set.{type Set}
import gleam/string
import simplifile

pub fn main() {
  let input = read_input("inputs/day16/input.txt")
  io.println("Part 1")
  part1(input) |> io.debug
}

pub fn part1(input: Map) {
  closest_node_iter(input)
  |> iterator.find(fn(it) { it.is_end })
}

pub type Direction {
  East
  West
  North
  South
}

pub type NodeKey {
  NodeKey(position: #(Int, Int), direction: Direction)
}

pub type Node {
  Node(
    position: #(Int, Int),
    direction: Direction,
    distance: Option(Int),
    is_end: Bool,
    neighbors: Set(#(NodeKey, Int)),
  )
}

fn node_key(node: Node) {
  NodeKey(node.position, node.direction)
}

pub type Map {
  Map(
    nodes: Dict(NodeKey, Node),
    visited: Set(NodeKey),
    candidates: Set(NodeKey),
  )
}

fn closest_node_iter(start_map: Map) -> Iterator(Node) {
  use map <- iterator.unfold(from: start_map)
  let Map(nodes, visited, candidates) = map
  let next_opt =
    candidates
    |> set.fold(None, fn(acc: Option(Node), it: NodeKey) {
      let assert Ok(next_node) = dict.get(map.nodes, it)
      case acc {
        None -> Some(next_node)
        Some(node) ->
          case node.distance, next_node.distance {
            Some(d1), Some(d2) if d2 < d1 -> Some(next_node)
            _, _ -> Some(node)
          }
      }
    })

  {
    use next_node <- option.map(next_opt)
    Next(next_node, visit(map, next_node))
  }
  |> option.unwrap(Done)
}

fn visit(map: Map, node: Node) -> Map {
  let Map(nodes, visited, candidates) = map
  let assert Some(current_distance) = node.distance
  let updated_visited = set.insert(visited, node_key(node))
  let adjacent =
    node.neighbors
    |> set.map(fn(it) {
      let #(key, distance) = it
      let total_distance = distance + current_distance
      let assert Ok(neighbor) = dict.get(nodes, key)
      case neighbor.distance {
        None -> Node(..neighbor, distance: Some(total_distance))
        Some(dist) if dist > total_distance ->
          Node(..neighbor, distance: Some(total_distance))
        _ -> neighbor
      }
    })
  let updated_nodes =
    adjacent
    |> set.fold(nodes, fn(acc, it) { dict.insert(acc, node_key(it), it) })
  let updated_candidates =
    adjacent
    |> set.map(node_key)
    |> set.difference(updated_visited)
    |> set.union(candidates)
    |> set.delete(node_key(node))
  Map(
    nodes: updated_nodes,
    visited: updated_visited,
    candidates: updated_candidates,
  )
}

fn read_input(filename: String) -> Map {
  let assert Ok(content) = simplifile.read(filename)
  let grid = coord_dict(content)

  let nodes =
    grid
    |> dict.fold(dict.new(), fn(nodes, coord, val) {
      let new_nodes = case val {
        "." -> make_nodes(grid, coord)
        "E" ->
          make_nodes(grid, coord)
          |> list.map(fn(it) { Node(..it, is_end: True) })
        "S" ->
          make_nodes(grid, coord)
          |> list.map(fn(it) {
            case it.direction {
              East -> Node(..it, distance: Some(0))
              _ -> it
            }
          })
        _ -> []
      }
      new_nodes
      |> list.fold(nodes, fn(acc, it) {
        acc
        |> dict.insert(node_key(it), it)
      })
    })
  let candidates =
    nodes
    |> dict.filter(fn(_, val) { option.is_some(val.distance) })
    |> dict.keys
    |> set.from_list

  Map(nodes: nodes, visited: set.new(), candidates: candidates)
}

fn make_nodes(
  grid: Dict(#(Int, Int), String),
  position: #(Int, Int),
) -> List(Node) {
  [East, West, North, South]
  |> list.map(fn(dir) {
    Node(
      position: position,
      direction: dir,
      distance: None,
      is_end: False,
      neighbors: find_neighbors(grid, NodeKey(position, dir)),
    )
  })
}

fn find_neighbors(
  grid: Dict(#(Int, Int), String),
  node: NodeKey,
) -> Set(#(NodeKey, Int)) {
  let NodeKey(#(x, y), direction) = node
  let turns =
    case direction {
      East | West -> [North, South]
      North | South -> [East, West]
    }
    |> list.map(fn(dir) { #(NodeKey(node.position, dir), 1000) })
    |> set.from_list
  let forward_tile = case direction {
    East -> #(x, y + 1)
    West -> #(x, y - 1)
    North -> #(x - 1, y)
    South -> #(x + 1, y)
  }
  case dict.get(grid, forward_tile) {
    Ok(".") | Ok("S") | Ok("E") ->
      set.insert(turns, #(NodeKey(forward_tile, direction), 1))
    _ -> turns
  }
}

fn coord_dict(input: String) -> Dict(#(Int, Int), String) {
  let arrays =
    input
    |> string.trim
    |> string.split("\n")
    |> list.map(string.to_graphemes)
  arrays
  |> list.index_fold(dict.new(), fn(acc, row, row_idx) {
    row
    |> list.index_fold(acc, fn(acc2, char, col_idx) {
      acc2
      |> dict.insert(#(row_idx, col_idx), char)
    })
  })
}
