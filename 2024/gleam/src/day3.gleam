import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import simplifile

pub fn main() {
  let input = read_input("inputs/day3/input.txt")
  io.println("Part 2")
  part2(input) |> io.debug
}

pub fn part2(input: Output) {
  input
  |> list.map(fn(pair) { pair.0 * pair.1 })
  |> int.sum
}

pub fn read_input(filename: String) {
  let assert Ok(content) = simplifile.read(filename)
  parse(content)
}

type Output =
  List(#(Int, Int))

type Parser {
  Default(input: String, parsed: Output)
  Disabled(input: String, parsed: Output)
  Open(input: String, parsed: Output)
  First(number: Int, input: String, parsed: Output)
}

fn parse(input: String) -> Output {
  let assert Default(_, parsed) = do_parse(Default(input, []))
  parsed
}

fn do_parse(parser: Parser) -> Parser {
  case parser {
    Default("mul(" <> rest, parsed) -> do_parse(Open(rest, parsed))
    Default("don't()" <> rest, parsed) -> do_parse(Disabled(rest, parsed))
    Default("", _) -> parser
    Default(input, parsed) -> {
      let assert Ok(#(_, rest)) = string.pop_grapheme(input)
      do_parse(Default(rest, parsed))
    }
    Disabled("do()" <> rest, parsed) -> do_parse(Default(rest, parsed))
    Disabled("", parsed) -> do_parse(Default("", parsed))
    Disabled(input, parsed) -> {
      let assert Ok(#(_, rest)) = string.pop_grapheme(input)
      do_parse(Disabled(rest, parsed))
    }
    Open(input, parsed) ->
      case parse_number(input) {
        Ok(#(num, "," <> rest)) -> do_parse(First(num, rest, parsed))
        _ -> do_parse(Default(input, parsed))
      }
    First(x, input, parsed) ->
      case parse_number(input) {
        Ok(#(y, ")" <> rest)) -> do_parse(Default(rest, [#(x, y), ..parsed]))
        _ -> do_parse(Default(input, parsed))
      }
  }
}

fn parse_number(input: String) -> Result(#(Int, String), Nil) {
  do_parse_number(input, "")
}

const all_digits = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]

fn do_parse_number(input: String, digits: String) -> Result(#(Int, String), Nil) {
  use #(next, rest) <- result.try(string.pop_grapheme(input))
  case list.any(all_digits, fn(x) { x == next }) {
    True -> do_parse_number(rest, digits <> next)
    False -> {
      use value <- result.map(int.parse(digits))
      #(value, input)
    }
  }
}
