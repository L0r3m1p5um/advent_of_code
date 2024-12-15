import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import pocket_watch
import simplifile

pub fn main() {
  let input = read_input("inputs/day9/input.txt")
  io.println("Part 2")
  use <- pocket_watch.simple("Part 2")
  part2(input) |> io.debug
}

fn part2(filesystem: Filesystem) -> Int {
  let indices =
    filesystem.files
    |> dict.keys
    |> list.sort(int.compare)
    |> list.reverse
  indices
  |> list.fold(filesystem, fn(acc, file_index) {
    case dict.get(filesystem.files, file_index) {
      Error(_) -> acc
      Ok(file) -> {
        compact_file(acc, file, file_index)
      }
    }
  })
  |> checksum
}

fn checksum(filesystem: Filesystem) -> Int {
  filesystem.files
  |> dict.to_list
  |> list.map(fn(entry) { file_checksum(entry.0, entry.1) })
  |> int.sum
}

fn file_checksum(start_index: Int, file: File) -> Int {
  list.range(start_index, { start_index + { file.size - 1 } })
  |> list.map(fn(index) { index * file.id })
  |> int.sum
}

fn compact_file(
  filesystem: Filesystem,
  file: File,
  file_index: Int,
) -> Filesystem {
  {
    use space <- result.map(find_lowest_space(filesystem.spaces, file.size))
    use <- bool.guard({ space.start_index > file_index }, filesystem)
    let Filesystem(files, spaces, id_max) = filesystem
    let new_files =
      files
      |> dict.delete(file_index)
      |> dict.insert(space.start_index, file)
    let remaining_space = case space.size - file.size {
      x if x <= 0 -> None
      x -> Some(Empty({ space.start_index + file.size }, x))
    }
    let new_spaces =
      remaining_space
      |> option.map(fn(space) { insert_space(spaces, space) })
      |> option.unwrap(spaces)
      |> dict.upsert(space.size, fn(value) {
        case value {
          // The lowest space is always pulled from the head
          // of the list, so it can be removed without checking if it's the same
          Some([_, ..rest]) -> rest
          // since find_lowest_space will pull the value from this same dict,
          // there should never be a case where the value is missing or is an
          // empty list
          _ -> panic
        }
      })
    Filesystem(new_files, new_spaces, id_max)
  }
  |> result.unwrap(filesystem)
}

fn insert_space(
  spaces: Dict(Int, List(Empty)),
  space: Empty,
) -> Dict(Int, List(Empty)) {
  spaces
  |> dict.upsert(space.size, fn(value) {
    case value {
      None -> [space]
      Some(space_list) -> {
        let #(before, after) =
          list.split_while(space_list, fn(it) {
            it.start_index < space.start_index
          })
        before |> list.append([space, ..after])
      }
    }
  })
}

fn find_lowest_space(
  spaces: Dict(Int, List(Empty)),
  size: Int,
) -> Result(Empty, Nil) {
  let candidates =
    spaces
    |> dict.fold([], fn(acc, key, value) {
      case key, value {
        key, _ if key < size -> acc
        _, [] -> acc
        _, [head, ..] -> [head, ..acc]
      }
    })
  candidates
  |> list.reduce(fn(lowest, it) {
    case it.start_index < lowest.start_index {
      True -> it
      False -> lowest
    }
  })
}

pub type File {
  File(id: Int, size: Int)
}

pub type Empty {
  Empty(start_index: Int, size: Int)
}

pub type Filesystem {
  Filesystem(
    // Dictionary of start index to file
    files: Dict(Int, File),
    // Dictionary of block size to list of empty blocks
    spaces: Dict(Int, List(Empty)),
    id_max: Int,
  )
}

type Parser {
  Parser(id: Int, index: Int, state: ParserState, filesystem: Filesystem)
}

type ParserState {
  ReadFile
  ReadEmpty
}

pub fn read_input(filename: String) -> Filesystem {
  let assert Ok(content) = simplifile.read(filename)
  {
    use parser, input <- list.fold(
      string.to_graphemes({ content |> string.drop_end(1) }),
      Parser(0, 0, ReadFile, Filesystem(dict.new(), dict.new(), 0)),
    )
    let assert Ok(count) = int.parse(input)
    case parser {
      Parser(id, index, ReadFile, Filesystem(files, spaces, _)) -> {
        Parser(
          id: { id + 1 },
          index: { index + count },
          state: ReadEmpty,
          filesystem: Filesystem(
            dict.insert(files, index, File(id, count)),
            spaces,
            id,
          ),
        )
      }
      Parser(id, index, ReadEmpty, Filesystem(files, spaces, id_max)) -> {
        let new_spaces =
          dict.upsert(spaces, count, fn(entry) {
            case entry {
              Some(values) -> [Empty(index, count), ..values]
              None -> [Empty(index, count)]
            }
          })
        Parser(
          id: id,
          index: { index + count },
          state: ReadFile,
          filesystem: Filesystem(files, new_spaces, id_max),
        )
      }
    }
  }
  |> fn(it) {
    let Parser(filesystem: Filesystem(files, spaces, id_max), ..) = it
    // Empty value arrays should be sorted by the lowest index
    Filesystem(
      files,
      dict.map_values(spaces, fn(_, it) { list.reverse(it) }),
      id_max,
    )
  }
}
