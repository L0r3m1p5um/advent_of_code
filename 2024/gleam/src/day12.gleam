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
  let input = read_input("inputs/day12/example.txt")
  io.println("Part 1")
  part1(input) |> io.debug
  io.println("Part 2")
  part2(input) |> io.debug
}

pub type Plot {
  Plot(location: #(Int, Int), perimeter: Int)
}

pub type Region {
  Region(letter: String, plots: Set(Plot))
}

fn part1(map: Dict(#(Int, Int), String)) -> Int {
  find_all_regions(map)
  |> list.map(price)
  |> int.sum
}

fn part2(map: Dict(#(Int, Int), String)) -> Int {
  find_all_regions(map)
  |> list.map(fn(it) {
    let sides =
      region_to_sides(it)
      |> set.size

    sides * set.size(it.plots)
  })
  |> int.sum
}

fn find_all_regions(map: Dict(#(Int, Int), String)) -> List(Region) {
  do_find_all_regions(map, [])
}

fn do_find_all_regions(
  map: Dict(#(Int, Int), String),
  regions: List(Region),
) -> List(Region) {
  case dict.is_empty(map) {
    True -> regions
    False -> {
      let assert Ok(start) =
        map
        |> dict.keys
        |> list.first
      let region = find_region(map, start)
      let next_map = remove_region(map, region)
      do_find_all_regions(next_map, [region, ..regions])
    }
  }
}

fn price(region: Region) -> Int {
  let Region(_, plots: plots) = region
  let perimeter =
    plots
    |> set.fold(0, fn(acc, it) { acc + it.perimeter })
  perimeter * set.size(plots)
}

fn remove_region(
  map: Dict(#(Int, Int), String),
  region: Region,
) -> Dict(#(Int, Int), String) {
  map
  |> dict.drop({
    region.plots
    |> set.map(fn(it) { it.location })
    |> set.to_list
  })
}

fn find_region(map: Dict(#(Int, Int), String), start: #(Int, Int)) -> Region {
  case dict.get(map, start) {
    Ok(letter) -> {
      let plots = do_find_region(map, letter, set.new(), set.from_list([start]))
      Region(letter, plots)
    }
    Error(_) -> panic
  }
}

fn do_find_region(
  map: Dict(#(Int, Int), String),
  letter: String,
  known_plots: Set(Plot),
  new_plots: Set(#(Int, Int)),
) -> Set(Plot) {
  case set.is_empty(new_plots) {
    True -> known_plots
    False -> {
      new_plots
      |> set.fold(#(set.new(), set.new()), fn(acc, it) {
        let #(row, col) = it
        let #(known, new) = acc
        let next_plots =
          [
            #({ row + 1 }, col),
            #({ row - 1 }, col),
            #(row, { col + 1 }),
            #(row, { col - 1 }),
          ]
          |> list.filter_map(fn(location) {
            case dict.get(map, location) {
              Ok(x) if x == letter -> Ok(location)
              _ -> Error(Nil)
            }
          })
          |> set.from_list
        let perimeter = 4 - set.size(next_plots)
        #(set.insert(known, Plot(it, perimeter)), set.union(next_plots, new))
      })
      |> fn(it) {
        let #(known, new) = it
        let updated_plots = set.union(known_plots, known)
        let updated_new =
          set.difference(new, set.map(updated_plots, fn(it) { it.location }))
        do_find_region(map, letter, updated_plots, updated_new)
      }
    }
  }
}

pub type Direction {
  Top
  Bottom
  Left
  Right
}

pub type Side {
  Side(components: List(#(Int, Int)), direction: Direction)
}

pub type MergeResult {
  NewSide(List(Side))
  NotSide
  NoMatch
}

fn merge_side(side1: Side, side2: Side) -> MergeResult {
  let limits = fn(s: Side) {
    use first <- result.try(list.first(s.components))
    use last <- result.map(list.last(s.components))
    #(first, last)
  }
  let flip = fn(it: Side) {
    let flipped =
      it.components
      |> list.map(fn(pair) { #(pair.1, pair.0) })
    Side(..it, components: flipped)
  }

  let flip_result = fn(it) {
    case it {
      NewSide(s) -> NewSide(list.map(s, flip))
      a -> a
    }
  }
  let merge = fn(s1: Side, s2: Side) {
    let Side(comp1, dir1) = s1
    let Side(comp2, _) = s2
    let assert Ok(#(start1, end1)) = limits(s1)
    let assert Ok(#(start2, end2)) = limits(s2)
    use <- bool.guard(start1.0 != start2.0, NoMatch)
    case start1, end1, start2, end2 {
      _, #(_, x), #(_, y), _ if y == x + 1 ->
        NewSide([Side(list.append(comp1, comp2), dir1)])
      #(_, x), _, _, #(_, y) if x == y + 1 -> {
        NewSide([Side(list.append(comp2, comp1), dir1)])
      }
      _, _, _, _ -> NoMatch
    }
  }

  let remove_overlap = fn(s1, s2) {
    let Side(comp1, dir1) = s1
    let Side(comp2, dir2) = s2
    let assert Ok(#(start1, _)) = limits(s1)
    let assert Ok(#(start2, _)) = limits(s2)
    use <- bool.guard({ start1.0 + 1 } != start2.0, NoMatch)
    let s1_indices =
      comp1
      |> list.map(fn(it) { it.1 })
      |> set.from_list
    let s2_indices =
      comp2
      |> list.map(fn(it) { it.1 })
      |> set.from_list
    let update = fn(idx1, idx2) {
      set.difference(idx1, idx2)
      |> set.to_list
      |> list.sort(int.compare)
      |> list.fold([], fn(acc, it) {
        case acc {
          [] -> [[it]]
          [[], ..rest] -> [[it], ..rest]
          [[x, ..xs], ..rest] if it == x + 1 -> [[it, x, ..xs], ..rest]
          other -> [[it], ..other]
        }
      })
    }
    let s1_updated =
      update(s1_indices, s2_indices)
      |> list.map(list.map(_, fn(it) { #(start1.0, it) }))
    let s2_updated =
      update(s2_indices, s1_indices)
      |> list.map(list.map(_, fn(it) { #(start2.0, it) }))
    case s1_updated, s2_updated {
      [], [] -> NotSide
      [], x -> NewSide(list.map(x, fn(it) { Side(it, dir2) }))
      x, [] -> NewSide(list.map(x, fn(it) { Side(it, dir1) }))
      [x], [y] if x == comp1 && y == comp2 -> NoMatch
      x, y ->
        list.map(x, fn(it) { Side(it, dir1) })
        |> list.append(list.map(y, fn(it) { Side(it, dir2) }))
        |> NewSide()
    }
  }

  case side1.direction, side2.direction {
    Top, Top -> merge(side1, side2)
    Bottom, Bottom -> merge(side1, side2)
    Left, Left -> merge(flip(side1), flip(side2)) |> flip_result
    Right, Right -> merge(flip(side1), flip(side2)) |> flip_result
    Bottom, Top -> remove_overlap(side1, side2)
    Top, Bottom -> remove_overlap(side2, side1)
    Right, Left -> remove_overlap(flip(side1), flip(side2)) |> flip_result
    Left, Right -> remove_overlap(flip(side2), flip(side1)) |> flip_result
    _, _ -> NoMatch
  }
}

fn region_to_sides(region: Region) -> Set(Side) {
  let locations = region.plots |> set.map(fn(it) { it.location })
  let all_sides =
    locations
    |> set.fold(set.new(), fn(acc, location) {
      [Top, Bottom, Left, Right]
      |> list.map(fn(it) { Side([location], it) })
      |> set.from_list
      |> set.union(acc)
    })
  consolidate_sides(all_sides)
  |> consolidate_sides
}

fn consolidate_sides(sides: Set(Side)) -> Set(Side) {
  let next =
    sides
    |> set.to_list
    |> list.fold([], fn(acc, side) {
      let #(new_acc, found) =
        acc
        |> list.fold(#([], False), fn(acc2, side2) {
          let #(list, found) = acc2
          case found {
            True -> #([side2, ..list], True)
            False ->
              case merge_side(side, side2) {
                NewSide(new_sides) -> #(list.append(new_sides, list), True)
                NotSide -> #(list, True)
                NoMatch -> #([side2, ..list], False)
              }
          }
        })
      case found {
        True -> new_acc
        False -> [side, ..new_acc]
      }
    })
    |> set.from_list
  case next == sides {
    True -> sides
    False -> consolidate_sides(next)
  }
}

pub fn read_input(filename: String) -> Dict(#(Int, Int), String) {
  let assert Ok(content) = simplifile.read(filename)
  content
  |> string.trim
  |> string.split("\n")
  |> list.index_map(fn(row, row_index) {
    row
    |> string.to_graphemes
    |> list.index_map(fn(value, col_index) { #(#(row_index, col_index), value) })
  })
  |> list.flatten
  |> dict.from_list
}
