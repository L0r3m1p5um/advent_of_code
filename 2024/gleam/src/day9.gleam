import gleam/bool
import gleam/int
import gleam/io
import gleam/list
import gleam/string
import pocket_watch
import simplifile

pub fn main() {
  let input = read_input("inputs/day9/input.txt")
  io.println("Part 1")
  use <- pocket_watch.simple("Part 1")
  part1(input) |> io.debug
}

pub fn part1(input: Filesystem) -> Int {
  compaction(input) |> checksum()
}

fn checksum(filesystem: Filesystem) -> Int {
  filesystem
  |> list.length
  |> list.range(0, _)
  |> list.zip(filesystem)
  |> list.fold(0, fn(acc, it) {
    let #(index, block) = it
    case block {
      Empty -> acc
      File(id) -> acc + { id * index }
    }
  })
}

fn compaction(filesystem: Filesystem) -> Filesystem {
  let total_files =
    list.count(filesystem, fn(block) {
      case block {
        File(_) -> True
        _ -> False
      }
    })
  do_compaction(filesystem, list.reverse(filesystem), [], 0, total_files)
}

fn do_compaction(
  head: Filesystem,
  tail: Filesystem,
  acc: Filesystem,
  processed_files: Int,
  total_files: Int,
) -> Filesystem {
  use <- bool.guard({ processed_files == total_files }, list.reverse(acc))
  case head, tail {
    [], _ -> panic
    [File(id), ..rest], _ ->
      do_compaction(
        rest,
        tail,
        [File(id), ..acc],
        { processed_files + 1 },
        total_files,
      )
    [Empty, ..], [Empty, ..tail_rest] ->
      do_compaction(head, tail_rest, acc, processed_files, total_files)
    [Empty, ..rest], [File(id), ..tail_rest] ->
      do_compaction(
        rest,
        tail_rest,
        [File(id), ..acc],
        { processed_files + 1 },
        total_files,
      )
    [Empty, ..], [] -> panic
  }
}

pub type Block {
  Empty
  File(Int)
}

type Filesystem =
  List(Block)

type Parser {
  Parser(id: Int, state: ParserState, filesystem: Filesystem)
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
      Parser(0, ReadFile, []),
    )
    let assert Ok(count) = int.parse(input)
    case parser {
      Parser(id, ReadFile, acc) -> {
        list.repeat(File(id), count)
        |> list.append(acc)
        |> Parser({ id + 1 }, ReadEmpty, _)
      }
      Parser(id, ReadEmpty, acc) -> {
        list.repeat(Empty, count)
        |> list.append(acc)
        |> Parser(id, ReadFile, _)
      }
    }
  }
  |> fn(it) {
    let Parser(filesystem: filesystem, ..) = it
    filesystem
  }
  |> list.reverse
}
