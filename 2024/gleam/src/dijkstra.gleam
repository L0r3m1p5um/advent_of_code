import gleam/dict.{type Dict}
import gleam/io
import gleam/iterator.{type Iterator, Done, Next}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/set.{type Set}

pub type Node(a) {
  Node(key: a, distance: Option(Int), neighbors: Set(#(a, Int)), is_end: Bool)
}

type Map(a) {
  Map(nodes: Dict(a, Node(a)), visited: Set(a), candidates: Set(a))
}

pub fn shortest_path(
  nodes nodes: b,
  start start: a,
  get_keys get_keys: fn(b) -> List(a),
  is_end is_end: fn(a) -> Bool,
  find_neighbors find_neighbors: fn(b, a) -> Set(#(a, Int)),
) -> Result(Int, Nil) {
  let map = create_map(nodes, start, get_keys, is_end, find_neighbors)
  map
  |> closest_node_iter
  |> iterator.find(fn(it) { it.is_end })
  |> result.try(fn(it) { it.distance |> option.to_result(Nil) })
}

fn create_map(
  nodes: b,
  start: a,
  get_keys: fn(b) -> List(a),
  is_end: fn(a) -> Bool,
  find_neighbors: fn(b, a) -> Set(#(a, Int)),
) -> Map(a) {
  let node_dict =
    nodes
    |> get_keys
    |> list.fold(dict.new(), fn(acc, it) {
      let distance = case it == start {
        True -> Some(0)
        False -> None
      }
      dict.insert(
        acc,
        it,
        Node(
          key: it,
          distance: distance,
          neighbors: find_neighbors(nodes, it),
          is_end: is_end(it),
        ),
      )
    })
  Map(node_dict, set.new(), set.from_list([start]))
}

// Iterates nodes in the order of the next closest unvisited
// node using Dijkstra's algorithm
fn closest_node_iter(start_map: Map(a)) -> Iterator(Node(a)) {
  use map <- iterator.unfold(from: start_map)
  // Find the closest unvisited node
  let next_node =
    map.candidates
    |> set.fold(None, fn(acc: Option(Node(a)), it: a) {
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

  case next_node {
    Some(node) -> Next(node, visit(map, node))
    None -> Done
  }
}

fn visit(map: Map(a), node: Node(a)) -> Map(a) {
  let Map(nodes, visited, candidates) = map
  let assert Some(current_distance) = node.distance
  let updated_visited = set.insert(visited, node.key)

  // The set of nodes reachable from the current node, with
  // the distance and path updated
  let adjacent =
    node.neighbors
    |> set.map(fn(it) {
      let #(key, weight) = it
      let total_distance = weight + current_distance
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
    |> set.fold(nodes, fn(acc, it) { dict.insert(acc, it.key, it) })
  let updated_candidates =
    adjacent
    |> set.map(fn(it) { it.key })
    |> set.filter(fn(key) { !set.contains(updated_visited, key) })
    |> set.union(candidates)
    |> set.delete(node.key)
  Map(
    nodes: updated_nodes,
    visited: updated_visited,
    candidates: updated_candidates,
  )
}
