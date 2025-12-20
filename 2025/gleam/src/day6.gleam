import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import simplifile

pub fn main() {
  io.println("Part 1")
  read_input("inputs/day6/input.txt")
  |> list.map(solve)
  |> int.sum
  |> echo

  io.println("Part 2")
  read_input2("inputs/day6/input.txt")
  |> list.map(solve)
  |> int.sum
  |> echo
}

fn solve(problem: Problem) -> Int {
  let assert Ok(result) = case problem.op {
    Mult -> problem.numbers |> list.reduce(int.multiply)
    Add -> problem.numbers |> list.reduce(int.add)
  }
  result
}

type Operation {
  Mult
  Add
}

type InputChar {
  Op(Operation)
  Num(Int)
}

type Problem {
  Problem(numbers: List(Int), op: Operation)
}

fn read_input2(filename: String) -> List(Problem) {
  let assert Ok(file) = simplifile.read(filename)
  let lines =
    file
    |> string.split("\n")
    |> list.filter(fn(x) { x != "" })
    |> list.map(fn(line) {
      line
      |> string.to_graphemes
      |> list.map(fn(char) {
        case char {
          " " -> None
          "*" -> Some(Op(Mult))
          "+" -> Some(Op(Add))
          num -> {
            let assert Ok(parsed) = int.parse(num)
            Some(Num(parsed))
          }
        }
      })
    })
  let transposed =
    lines |> list.transpose |> list.reverse |> list.map(option.values)
  let parse_row = fn(row) {
    row
    |> list.fold(#(0, None), fn(acc, input) {
      let #(sum, _) = acc
      case input {
        Op(op) -> #(sum, Some(op))
        Num(n) -> #(sum * 10 + n, None)
      }
    })
  }
  let #(problems, _) =
    transposed
    |> list.fold(#([], []), fn(acc, row) {
      let #(problems, nums) = acc
      case row {
        [] -> acc
        _ ->
          case parse_row(row) {
            #(num, None) -> #(problems, [num, ..nums])
            #(num, Some(op)) -> #([Problem([num, ..nums], op), ..problems], [])
          }
      }
    })
  problems
}

fn read_input(filename: String) -> List(Problem) {
  let assert Ok(file) = simplifile.read(filename)
  let assert [opline, ..lines] =
    file
    |> string.split("\n")
    |> list.filter(fn(x) { x != "" })
    |> list.map(fn(line) {
      line |> string.split(" ") |> list.filter(fn(word) { word != "" })
    })
    |> list.reverse
  let ops =
    opline
    |> list.map(fn(str) {
      case str {
        "*" -> Mult
        "+" -> Add
        _ -> panic
      }
    })
  let numbers =
    lines
    |> list.fold(dict.new(), fn(acc, line) {
      let assert Ok(parsed) = line |> list.map(int.parse) |> result.all
      parsed
      |> list.index_fold(acc, fn(acc, num, idx) {
        acc
        |> dict.upsert(idx, fn(entry) {
          case entry {
            Some(nums) -> [num, ..nums]
            None -> [num]
          }
        })
      })
    })
  ops
  |> list.index_map(fn(op, idx) {
    let assert Ok(nums) = numbers |> dict.get(idx)
    Problem(nums, op)
  })
}
