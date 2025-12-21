import gleam/dict.{type Dict}
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/pair
import gleam/result
import gleam/set.{type Set}
import gleam/string
import simplifile

pub fn main() {
  let state = read_input("inputs/day8/input.txt") |> state_init

  io.println("Part 1")
  Incomplete(state) |> run_steps(1000) |> calculate_top_three |> echo

  io.println("Part 2")
  let #(a, b) = state |> run_complete
  a.x *. b.x |> echo
}

type Coordinates {
  Coordinates(x: Float, y: Float, z: Float, id: NodeId)
}

type State {
  State(
    unconnected: Set(#(NodeId, NodeId)),
    nodes: Dict(NodeId, Coordinates),
    sorted_connections: List(#(NodeId, NodeId)),
    circuit_map: Dict(NodeId, CircuitId),
    circuits: Dict(CircuitId, Set(NodeId)),
    circuit_idx: Int,
  )
}

type NodeId {
  NodeId(value: Int)
}

type CircuitId {
  CircuitId(value: Int)
}

fn calculate_top_three(state: State) -> Int {
  state.circuits
  |> dict.values
  |> list.map(set.size)
  |> list.sort(int.compare)
  |> list.reverse
  |> list.take(3)
  |> list.fold(1, int.multiply)
}

fn show_circuits(state: State) -> State {
  state.circuits
  |> dict.values
  |> list.map(fn(circuit) {
    circuit
    |> set.to_list
    |> list.map(fn(id) { state.nodes |> dict.get(id) })
    |> echo
  })
  state
}

fn state_init(coords: List(Coordinates)) -> State {
  let nodes =
    coords
    |> list.fold(dict.new(), fn(acc, it) { acc |> dict.insert(it.id, it) })
  let distances =
    coords
    |> list.combination_pairs
    |> list.fold(dict.new(), fn(acc, coord_pair) {
      let #(a, b) = coord_pair
      acc |> dict.insert(make_connection(a.id, b.id), distance(a, b))
    })
  State(
    unconnected: { distances |> dict.keys |> set.from_list },
    nodes: nodes,
    sorted_connections: sort_distances(distances),
    circuit_map: dict.new(),
    circuits: dict.new(),
    circuit_idx: 0,
  )
}

fn run_steps(status: RunStatus, steps: Int) -> State {
  case status, steps {
    _, x if x < 0 -> panic
    Incomplete(state), 0 -> state
    Incomplete(state), _ -> run_steps(connection_step(state), steps - 1)
    Complete(state, _), _ -> state
  }
}

fn run_complete(state: State) -> #(Coordinates, Coordinates) {
  case connection_step(state) {
    Complete(state, last) -> {
      let assert Ok(x) = state.nodes |> dict.get(last.0)
      let assert Ok(y) = state.nodes |> dict.get(last.1)
      #(x, y)
    }
    Incomplete(state) -> run_complete(state)
  }
}

type RunStatus {
  Complete(State, #(NodeId, NodeId))
  Incomplete(State)
}

fn connection_step(state: State) -> RunStatus {
  let assert [next_connection, ..remaining] = state.sorted_connections
  let new_state = case set.contains(state.unconnected, next_connection) {
    True -> {
      let connected = state |> add_connection(next_connection)
      State(..connected, sorted_connections: remaining)
    }
    False -> State(..state, sorted_connections: remaining)
  }
  case new_state.unconnected |> set.size {
    0 -> Complete(new_state, next_connection)
    _ -> Incomplete(new_state)
  }
}

fn add_connection(state: State, connection: #(NodeId, NodeId)) {
  let #(node1, node2) = connection
  let circuit1 = state.circuit_map |> dict.get(node1)
  let circuit2 = state.circuit_map |> dict.get(node2)
  case circuit1, circuit2 {
    Error(Nil), Error(Nil) -> create_circuit(state, node1, node2)
    Error(Nil), Ok(c_id) -> state |> add_node_to_circuit(node1, c_id)
    Ok(c_id), Error(Nil) -> state |> add_node_to_circuit(node2, c_id)
    Ok(c1), Ok(c2) -> state |> merge_circuits(c1, c2)
  }
}

fn create_circuit(state: State, node1: NodeId, node2: NodeId) -> State {
  let State(
    circuit_map: circuit_map,
    circuits: circuits,
    circuit_idx: circuit_idx,
    unconnected: unconnected,
    ..,
  ) = state
  let circuit_id = CircuitId(circuit_idx)
  let updated_map =
    circuit_map
    |> dict.insert(node1, circuit_id)
    |> dict.insert(node2, circuit_id)
  let updated_circuits =
    circuits |> dict.insert(circuit_id, { [node1, node2] |> set.from_list })
  State(
    ..state,
    unconnected: unconnected |> set.delete(make_connection(node1, node2)),
    circuit_map: updated_map,
    circuits: updated_circuits,
    circuit_idx: circuit_idx + 1,
  )
}

fn make_connection(node1: NodeId, node2: NodeId) {
  case node1.value < node2.value {
    True -> #(node1, node2)
    False -> #(node2, node1)
  }
}

fn add_node_to_circuit(
  state: State,
  node_id: NodeId,
  circuit_id: CircuitId,
) -> State {
  let assert Ok(circuit) = state.circuits |> dict.get(circuit_id)
  let new_connected =
    circuit
    |> set.map(make_connection(_, node_id))
  let new_unconnected = state.unconnected |> set.difference(new_connected)
  State(
    ..state,
    unconnected: new_unconnected,
    circuit_map: state.circuit_map |> dict.insert(node_id, circuit_id),
    circuits: state.circuits
      |> dict.insert(circuit_id, { circuit |> set.insert(node_id) }),
  )
}

fn merge_circuits(state: State, cid1: CircuitId, cid2: CircuitId) -> State {
  let assert Ok(circuit1) = state.circuits |> dict.get(cid1)
  let assert Ok(circuit2) = state.circuits |> dict.get(cid2)
  let new_connections =
    circuit1
    |> set.map(fn(node1) {
      circuit2 |> set.map(fn(node2) { make_connection(node1, node2) })
    })
    |> set.fold(set.new(), set.union)
  let new_unconnected = state.unconnected |> set.difference(new_connections)
  State(
    ..state,
    unconnected: new_unconnected,
    circuits: state.circuits
      |> dict.insert(cid1, set.union(circuit1, circuit2))
      |> dict.delete(cid2),
    circuit_map: circuit2
      |> set.fold(state.circuit_map, fn(acc, node) {
        acc |> dict.insert(node, cid1)
      }),
  )
}

fn sort_distances(
  distances: Dict(#(NodeId, NodeId), Float),
) -> List(#(NodeId, NodeId)) {
  distances
  |> dict.keys
  |> list.sort(fn(x, y) {
    let assert Ok(dx) = distances |> dict.get(x)
    let assert Ok(dy) = distances |> dict.get(y)
    float.compare(dx, dy)
  })
}

fn distance(a: Coordinates, b: Coordinates) -> Float {
  let f = fn(x, y) { { x -. y } *. { x -. y } }
  let assert Ok(result) =
    { f(a.x, b.x) +. f(a.y, b.y) +. f(a.z, b.z) } |> float.square_root
  result
}

fn read_input(filename: String) -> List(Coordinates) {
  let assert Ok(file) = simplifile.read(filename)

  file
  |> string.split("\n")
  |> list.filter(fn(x) { x != "" })
  |> list.index_map(fn(line, id) {
    let assert [x, y, z] =
      line
      |> string.split(",")
      |> list.map(fn(x) {
        let assert Ok(result) = int.parse(x)
        int.to_float(result)
      })
    Coordinates(x, y, z, NodeId(id))
  })
}
