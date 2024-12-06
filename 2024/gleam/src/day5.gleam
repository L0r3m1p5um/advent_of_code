import gleam/bool
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

pub fn main() {
  let #(rules, updates) = read_input("inputs/day5/input.txt")
  io.println("Part 1")
  part1(rules, updates) |> io.debug
  io.println("Part 2")
  part2(rules, updates) |> io.debug
}

pub fn part1(rules: List(Rule), updates: List(List(Int))) -> Int {
  updates
  |> list.filter(check_update(rules, _))
  |> middle_values
  |> int.sum
}

fn middle_values(updates: List(List(Int))) -> List(Int) {
  updates
  |> list.map(fn(update) {
    let assert Ok(drop_length) = int.floor_divide(list.length(update), 2)
    let assert [mid, ..] = list.drop(update, drop_length)
    mid
  })
}

fn check_update(rules: List(Rule), update: List(Int)) -> Bool {
  update
  |> list.fold(Ok(rules), fn(acc, it) {
    case acc {
      Ok(rules) -> check_page(rules, it)
      err -> err
    }
  })
  |> result.is_ok
}

fn check_page(rules: List(Rule), page: Int) -> Result(List(Rule), Nil) {
  use <- bool.guard(
    {
      rules
      |> list.find(fn(rule) {
        case rule {
          Rule(x, _, True) if x == page -> True
          _ -> False
        }
      })
      |> result.is_ok
    },
    Error(Nil),
  )
  list.filter(rules, fn(rule) { rule.first != page })
  |> list.map(fn(rule) {
    case rule {
      Rule(x, y, _) if y == page -> Rule(x, y, True)
      it -> it
    }
  })
  |> Ok
}

pub fn part2(rules: List(Rule), updates: List(List(Int))) -> Int {
  let incorrect = updates |> list.filter(fn(it) { !check_update(rules, it) })
  incorrect
  |> list.map(fn(update) {
    let relevant_rules = rules |> filter_relevant(update)
    order_update(update, relevant_rules)
  })
  |> middle_values
  |> int.sum
}

fn filter_relevant(rules: List(Rule), update: List(Int)) -> List(Rule) {
  rules
  |> list.filter(fn(rule) {
    let Rule(fst, snd, _) = rule
    list.contains(update, fst) && list.contains(update, snd)
  })
}

fn order_update(update: List(Int), rules: List(Rule)) -> List(Int) {
  do_order_update(update, rules, []) |> list.reverse
}

fn do_order_update(
  update: List(Int),
  rules: List(Rule),
  ordered: List(Int),
) -> List(Int) {
  case update {
    [] -> ordered
    _ -> {
      let assert Ok(#(next, rest)) =
        list.pop(update, fn(it) { no_prerequisites(rules, it) })
      let remaining_rules =
        list.filter(rules, fn(rule) {
          case rule {
            Rule(x, y, _) if x == next || y == next -> False
            _ -> True
          }
        })
      do_order_update(rest, remaining_rules, [next, ..ordered])
    }
  }
}

fn no_prerequisites(rules: List(Rule), page: Int) -> Bool {
  list.all(rules, fn(rule) {
    case rule {
      Rule(_, it, _) if it == page -> False
      _ -> True
    }
  })
}

pub type Rule {
  Rule(first: Int, second: Int, matched: Bool)
}

pub fn read_input(filename: String) -> #(List(Rule), List(List(Int))) {
  let assert Ok(content) = simplifile.read(filename)
  let assert [rulesstr, pages] = string.split(content, "\n\n")
  let parse_rule = fn(str) -> Rule {
    let assert [fst, snd] = string.split(str, "|")
    let assert Ok(before) = int.parse(fst)
    let assert Ok(after) = int.parse(snd)
    Rule(before, after, False)
  }

  let rules =
    rulesstr
    |> string.split("\n")
    |> list.map(parse_rule)

  let assert Ok(updates) =
    pages
    |> string.drop_end(1)
    |> string.split("\n")
    |> list.map(fn(it) {
      string.split(it, ",")
      |> list.map(int.parse)
      |> result.all
    })
    |> result.all
  #(rules, updates)
}
