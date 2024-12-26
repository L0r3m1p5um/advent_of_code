import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/iterator.{type Iterator, Done, Next}
import gleam/list
import gleam/result
import gleam/string
import pocket_watch
import simplifile
import util
import utils

pub fn main() {
  let input = read_input("inputs/day17/input.txt") |> io.debug
  io.println("Part 1")
  part1(input) |> io.debug
}

pub fn part1(input: Computer) -> String {
  let assert Ok(done) =
    run(input)
    |> iterator.last
  done.output
  |> list.reverse
  |> list.map(int.to_string)
  |> string.join(",")
}

pub fn part2(input: Computer) -> Int {
  let assert Ok(result) =
    iterator.iterate(1, fn(it) { it + 1 })
    |> iterator.find(fn(it) { try_input(input, it) })
  result
}

fn try_input(computer: Computer, a_val: Int) -> Bool {
  let end =
    write(computer, A, a_val)
    |> run
    |> iterator.take_while(fn(it) { it.match_result != NoMatch })
    |> iterator.last
  case end {
    Ok(Computer(match_result: Matched, ..)) -> True
    _ -> False
  }
}

pub type Computer {
  Computer(
    registers: Registers,
    program: Dict(Int, Instruction),
    pc: Int,
    output: List(Int),
    match_result: MatchResult,
  )
}

pub type MatchResult {
  Matched
  NoMatch
  Incomplete(List(Int))
}

pub type Registers {
  Registers(a: Int, b: Int, c: Int)
}

pub type Register {
  A
  B
  C
}

pub type OpCode {
  Adv
  Bxl
  Bst
  Jnz
  Bxc
  Out
  Bdv
  Cdv
}

pub type Operand {
  Lit(Int)
  Combo(Register)
}

pub type Instruction {
  Instruction(opcode: OpCode, operand: Operand)
}

fn read(computer: Computer, register: Register) -> Int {
  case register {
    A -> computer.registers.a
    B -> computer.registers.b
    C -> computer.registers.c
  }
}

fn write(computer: Computer, register: Register, value: Int) -> Computer {
  let registers = computer.registers
  case register {
    A -> Registers(..registers, a: value)
    B -> Registers(..registers, b: value)
    C -> Registers(..registers, c: value)
  }
  |> fn(it) { Computer(..computer, registers: it) }
}

fn run(start: Computer) -> iterator.Iterator(Computer) {
  use computer <- iterator.unfold(start)
  let next_instruction = dict.get(computer.program, computer.pc)
  case next_instruction {
    Error(Nil) -> Done
    Ok(inst) -> {
      computer
      |> run_instruction(inst)
      |> fn(it) { Next(it, it) }
    }
  }
}

fn run_instruction(computer: Computer, instruction: Instruction) {
  let Instruction(opcode, operand) = instruction
  computer
  |> case opcode {
    Adv -> dv(_, A, operand)
    Bxl -> bxl(_, operand)
    Bst -> bst(_, operand)
    Jnz -> jnz(_, operand)
    Bxc -> bxc
    Out -> out(_, operand)
    Bdv -> dv(_, B, operand)
    Cdv -> dv(_, C, operand)
  }
}

fn step_instruction(computer: Computer) -> Computer {
  Computer(..computer, pc: computer.pc + 2)
}

fn operand_value(computer: Computer, operand: Operand) -> Int {
  case operand {
    Lit(val) -> val
    Combo(reg) -> read(computer, reg)
  }
}

fn dv(computer: Computer, register: Register, operand: Operand) -> Computer {
  let numerator = read(computer, A)
  let denominator = utils.power(2, operand_value(computer, operand))
  computer
  |> write(register, numerator / denominator)
  |> step_instruction
}

fn bxl(computer: Computer, operand: Operand) -> Computer {
  let assert Lit(val) = operand
  let xor = int.bitwise_exclusive_or(val, read(computer, B))
  write(computer, B, xor)
  |> step_instruction
}

fn bst(computer: Computer, operand: Operand) -> Computer {
  let new_val =
    computer
    |> operand_value(operand)
    |> fn(it) { it % 8 }
  computer
  |> write(B, new_val)
  |> step_instruction
}

fn jnz(computer: Computer, operand: Operand) -> Computer {
  case read(computer, A) {
    0 -> computer |> step_instruction
    _ -> {
      let assert Lit(addr) = operand
      Computer(..computer, pc: addr)
    }
  }
}

fn bxc(computer: Computer) -> Computer {
  let b = read(computer, B)
  let c = read(computer, C)
  computer
  |> write(B, int.bitwise_exclusive_or(b, c))
  |> step_instruction
}

fn out(computer: Computer, operand: Operand) -> Computer {
  let val = operand_value(computer, operand) |> fn(it) { it % 8 }
  let match = case computer.match_result {
    Incomplete([next]) if next == val -> Matched
    Incomplete([next, ..rest]) if next == val -> Incomplete(rest)
    Incomplete(_) -> NoMatch
    Matched -> NoMatch
    NoMatch -> NoMatch
  }
  Computer(..computer, output: [val, ..computer.output], match_result: match)
  |> step_instruction
}

pub fn read_input(filename: String) -> Computer {
  let assert Ok(content) = simplifile.read(filename)
  let assert Ok(#(registers, program)) =
    content
    |> string.trim
    |> string.split_once("\n\n")
  let #(instructions, bytes) = parse_program(program)
  Computer(
    registers: parse_registers(registers),
    program: instructions,
    pc: 0,
    output: [],
    match_result: Incomplete(bytes),
  )
}

fn parse_program(input: String) -> #(Dict(Int, Instruction), List(Int)) {
  let assert Ok(bytes) =
    input
    |> string.drop_left(9)
    |> string.split(",")
    |> list.map(int.parse)
    |> result.all
  let instructions =
    bytes
    |> list.window_by_2
    |> list.map(parse_instruction)
    |> list.index_fold(dict.new(), fn(acc, it, idx) {
      dict.insert(acc, idx, it)
    })
  #(instructions, bytes)
}

fn combo(operand: Int) -> Operand {
  case operand {
    x if 0 <= x && x <= 3 -> Lit(x)
    4 -> Combo(A)
    5 -> Combo(B)
    6 -> Combo(C)
    _ -> panic as "Invalid operand"
  }
}

fn parse_instruction(input: #(Int, Int)) -> Instruction {
  case input {
    #(0, x) -> Instruction(Adv, combo(x))
    #(1, x) -> Instruction(Bxl, Lit(x))
    #(2, x) -> Instruction(Bst, combo(x))
    #(3, x) -> Instruction(Jnz, Lit(x))
    #(4, x) -> Instruction(Bxc, Lit(x))
    #(5, x) -> Instruction(Out, combo(x))
    #(6, x) -> Instruction(Bdv, combo(x))
    #(7, x) -> Instruction(Cdv, combo(x))
    _ -> panic as "Invalid opcode"
  }
}

fn parse_registers(input: String) -> Registers {
  let assert Ok([a, b, c]) =
    input
    |> string.trim
    |> string.split("\n")
    |> list.map(string.drop_start(_, 12))
    |> list.map(int.parse)
    |> result.all

  Registers(a, b, c)
}
