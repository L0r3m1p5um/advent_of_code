import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/set.{type Set}
import gleam/string
import gleam/yielder.{type Step, Done, Next}
import simplifile
import utils

pub fn main() {
  let input = read_input("inputs/day7/input.txt")
  io.println("Part 1")
  input |> part1 |> echo
  io.println("Part 2")
  input |> part2 |> echo
}

fn part1(map) {
  let assert Ok(complete) = map |> yielder.unfold(do_row) |> yielder.last
  complete.times_split
}

fn part2(map: Map) {
  let #(rows, columns) = map.dimensions
  let row_indices = list.range(0, rows)
  let col_indices = list.range(0, columns)
  // dict of the all possible start coordinates to the count of timelines from that coordinate
  let timeline_map =
    row_indices
    // Iterating backwards allows the number of timelines to be counted based
    // on the accumulated timelines below it. Timelines on the bottom row are simple to count,
    // They're just two timelines if theres a split there and one if not.
    |> list.reverse
    |> list.fold(dict.new(), fn(acc, row_idx) {
      let splitters =
        map.splitters
        |> dict.get(row_idx)
        |> result.unwrap(set.new())
      col_indices
      |> list.fold(acc, fn(acc, col_idx) {
        case set.contains(splitters, col_idx) {
          True -> {
            // If the column splits, the number of timelines is the sum of the number of
            // timelines created by the left and right options
            let left =
              // If we can't find an entry for the number below, we can assume that we're at the
              // bottom row and therefore there's only one possible timeline for each option.
              acc |> dict.get(#(row_idx + 1, col_idx - 1)) |> result.unwrap(1)
            let right =
              acc |> dict.get(#(row_idx + 1, col_idx + 1)) |> result.unwrap(1)
            acc |> dict.insert(#(row_idx, col_idx), left + right)
          }
          False -> {
            // If there's no split, the number of timelines is the same as the number of timelines
            // created by the row directly below it.
            let timelines =
              acc |> dict.get(#(row_idx + 1, col_idx)) |> result.unwrap(1)
            acc |> dict.insert(#(row_idx, col_idx), timelines)
          }
        }
      })
    })

  // Select the timeline count corresponding to the actual start point.
  let assert Ok(start) = map.beams |> set.to_list |> list.first
  timeline_map |> dict.get(#(0, start))
}

type Map {
  Map(
    // A set is used here for the sake of part 1. This deduplicates beams when they're
    // recombined from two splits above them.
    beams: Set(Int),
    // Dict of the row index to all of the column indices containing a splitter in that row.
    splitters: Dict(Int, Set(Int)),
    times_split: Int,
    row: Int,
    // the dimensions of the map: #(row_count, column_count)
    dimensions: #(Int, Int),
  )
}

// Handles advancing the state one step for part 1
fn do_row(map: Map) -> Step(Map, Map) {
  let Map(beams, splitter_dict, times_split, row, dimensions) = map
  case splitter_dict |> dict.get(row) {
    Error(Nil) -> Done
    Ok(splitters) -> {
      let splitters_hit = beams |> set.intersection(splitters)
      let splitters_missed = beams |> set.difference(splitters)
      let new_beams =
        splitters_hit
        |> set.fold(set.new(), fn(acc, x) {
          // Hit beams get divided into the adjacent column indices
          acc |> set.union(set.from_list([x - 1, x + 1]))
        })
        // Beams that missed a splitter stay at the same index.
        |> set.union(splitters_missed)
      let next =
        Map(
          beams: new_beams,
          splitters: splitter_dict,
          times_split: times_split + set.size(splitters_hit),
          row: row + 1,
          dimensions: dimensions,
        )
      Next(next, next)
    }
  }
}

fn read_input(filename: String) -> Map {
  let assert Ok(file) = simplifile.read(filename)
  let assert [first, ..lines] =
    file
    |> string.split("\n")
    |> list.filter(fn(x) { x != "" })
    |> list.sized_chunk(2)
    |> list.map(fn(chunk) {
      // Every other row is always empty, those can be thrown out
      let assert [first, _] = chunk
      first |> string.to_graphemes
    })
  let assert Some(start) =
    first
    |> list.index_fold(None, fn(acc, char, idx) {
      case char {
        "S" -> Some(idx)
        _ -> acc
      }
    })
  let splitters =
    lines
    |> utils.fold_coords(dict.new(), fn(acc, char, coords) {
      let #(row, col) = coords
      case char {
        "^" ->
          acc
          |> dict.upsert(row, fn(splitters) {
            case splitters {
              None -> set.from_list([col])
              Some(x) -> x |> set.insert(col)
            }
          })
        _ -> acc
      }
    })

  Map(
    // In the initial state, the only beam is at the start index
    beams: set.from_list([start]),
    splitters: splitters,
    times_split: 0,
    row: 0,
    dimensions: #(list.length(lines), list.length(first)),
  )
}
