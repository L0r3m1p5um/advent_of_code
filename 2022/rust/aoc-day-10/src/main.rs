#![feature(iterator_try_collect)]

use color_eyre::eyre::eyre;
use color_eyre::eyre::ErrReport;

fn main() -> color_eyre::Result<()> {
    color_eyre::install()?;
    part2()?;
    Ok(())
}

fn part1() -> color_eyre::Result<()> {
    let source = include_str!("program.txt");
    let mut program = Program::new(source, vec![20, 60, 100, 140, 180, 220])?;
    program.execute();
    println!("{:?}", program.signal_strengths.iter().sum::<i32>());
    Ok(())
}

fn part2() -> color_eyre::Result<()> {
    let source = include_str!("program.txt");
    let mut program = Program::new(source, vec![20, 60, 100, 140, 180, 220])?;
    program.execute();
    program.draw_display();
    Ok(())
}

#[derive(Debug)]
enum Instruction {
    Noop,
    Addx(i32),
}

struct Program {
    instructions: Vec<Instruction>,
    cycle: u32,
    signal_index: usize,
    signal_cycles: Vec<u32>,
    signal_strengths: Vec<i32>,
    x_register: i32,
    display: Vec<char>,
}

impl Program {
    fn new(source: &str, mut signal_cycles: Vec<u32>) -> color_eyre::Result<Self> {
        let instructions = Program::compile(source)?;
        signal_cycles.sort();
        Ok(Program {
            instructions,
            cycle: 1,
            signal_index: 0,
            signal_cycles,
            x_register: 1,
            signal_strengths: vec![],
            display: vec![],
        })
    }
    fn compile(source: &str) -> color_eyre::Result<Vec<Instruction>> {
        let instructions: Result<Vec<Instruction>, ErrReport> = source
            .lines()
            .map(|line| {
                let mut line = line.split(" ");
                match line.next() {
                    Some("noop") => Ok(Some(Instruction::Noop)),
                    Some("addx") => Ok(Some(Instruction::Addx(
                        line.next().unwrap().parse::<i32>().unwrap(),
                    ))),
                    Some(x) => Err(eyre!("Invalid instruction: {}", x)),
                    None => Ok(None),
                }
            })
            .filter(|instruction| match instruction {
                Ok(None) => false,
                _ => true,
            })
            .map(|instruction| match instruction {
                Ok(Some(x)) => Ok(x),
                Ok(None) => panic!(),
                Err(x) => Err(x),
            })
            .try_collect();
        Ok(instructions?)
    }

    fn execute(&mut self) {
        for instruction in &self.instructions {
            let current_x = self.x_register;
            match instruction {
                Instruction::Noop => {
                    match current_x - ((self.cycle - 1) % 40) as i32 {
                        -1 | 0 | 1 => self.display.push('#'),
                        _ => self.display.push('.'),
                    }
                    self.cycle += 1;
                }
                Instruction::Addx(x) => {
                    match current_x - ((self.cycle - 1) % 40) as i32 {
                        -1 | 0 | 1 => self.display.push('#'),
                        _ => self.display.push('.'),
                    }
                    match current_x - (self.cycle % 40) as i32 {
                        -1 | 0 | 1 => self.display.push('#'),
                        _ => self.display.push('.'),
                    }
                    self.cycle += 2;
                    self.x_register += x;
                }
            }

            let next_signal = self.signal_cycles.get(self.signal_index).clone();
            match next_signal {
                Some(&sig_cycle) if sig_cycle < self.cycle => {
                    self.signal_strengths.push(sig_cycle as i32 * current_x);
                    self.signal_index += 1;
                }
                _ => {}
            }
        }
    }

    fn draw_display(&self) {
        let mut output = self.display.iter().collect::<String>();
        if output.len() < 240 {
            output += &".".repeat(240 - output.len());
        }
        for i in 1..6 {
            output.insert((6 - i) * 40, '\n');
        }
        println!("{}", output);
    }
}
