use std::{
    fs::File,
    io::{BufRead, BufReader},
    path::Path,
};

use anyhow::{anyhow, Ok, Result};

fn main() {
    part1().unwrap();
    part2().unwrap();
}

fn part1() -> Result<()> {
    let path = Path::new("instructions.txt");
    let file = File::open(path)?;
    let mut stacks = stack_init();
    BufReader::new(file).lines().for_each(|line| {
        stacks
            .execute_instruction(&line.unwrap(), CrateMoverVersion::V9000)
            .unwrap()
    });
    println!("Part 1: {:?}", stacks.top_crates());
    Ok(())
}

fn part2() -> Result<()> {
    let path = Path::new("instructions.txt");
    let file = File::open(path)?;
    let mut stacks = stack_init();
    BufReader::new(file).lines().for_each(|line| {
        stacks
            .execute_instruction(&line.unwrap(), CrateMoverVersion::V9001)
            .unwrap()
    });
    println!("Part 2: {:?}", stacks.top_crates());
    Ok(())
}

// fn test_stack_init() -> Supplies {
//     let mut stacks = vec![];
//     stacks.push(vec!['Z', 'N']);
//     stacks.push(vec!['M', 'C', 'D']);
//     stacks.push(vec!['P']);
//     Supplies { stacks }
// }

fn stack_init() -> Supplies {
    let stacks = vec![
        vec!['J', 'H', 'P', 'M', 'S', 'F', 'N', 'V'],
        vec!['S', 'R', 'L', 'M', 'J', 'D', 'Q'],
        vec!['N', 'Q', 'D', 'H', 'C', 'S', 'W', 'B'],
        vec!['R', 'S', 'C', 'L'],
        vec!['M', 'V', 'T', 'P', 'F', 'B'],
        vec!['T', 'R', 'Q', 'N', 'C'],
        vec!['G', 'V', 'R'],
        vec!['C', 'Z', 'S', 'P', 'D', 'L', 'R'],
        vec!['D', 'S', 'J', 'V', 'G', 'P', 'B', 'F'],
    ];
    Supplies { stacks }
}

#[derive(Debug)]
struct Supplies {
    stacks: Vec<Vec<char>>,
}

enum CrateMoverVersion {
    V9000,
    V9001,
}

impl Supplies {
    fn move_crate(&mut self, source: usize, target: usize) -> Result<()> {
        let source_stack = self
            .stacks
            .get_mut(source - 1)
            .ok_or_else(|| anyhow!("Invalid source stack index"))?;
        let crate_ = source_stack.pop().unwrap();
        let target_stack = self
            .stacks
            .get_mut(target - 1)
            .ok_or_else(|| anyhow!("Invalid destination stack index"))?;
        target_stack.push(crate_);
        Ok(())
    }

    fn move_multiple_crates(
        &mut self,
        count: usize,
        source: usize,
        target: usize,
        version: CrateMoverVersion,
    ) -> Result<()> {
        match version {
            CrateMoverVersion::V9000 => {
                for _ in 0..count {
                    self.move_crate(source, target)?;
                }
            }
            CrateMoverVersion::V9001 => {
                let source_stack = self
                    .stacks
                    .get_mut(source - 1)
                    .ok_or_else(|| anyhow!("Invalid source stack index"))?;
                let length = source_stack.len();
                let mut crates: Vec<char> = source_stack.drain(length - count..length).collect();
                let target_stack = self
                    .stacks
                    .get_mut(target - 1)
                    .ok_or_else(|| anyhow!("Invalid target stack"))?;
                target_stack.append(&mut crates);
            }
        }
        Ok(())
    }

    fn top_crates(&self) -> String {
        self.stacks
            .iter()
            .map(|stack| stack.last().unwrap().to_string())
            .reduce(|x, y| x + &y)
            .unwrap()
    }

    fn execute_instruction(&mut self, instruction: &str, version: CrateMoverVersion) -> Result<()> {
        let instruction: Vec<&str> = instruction.split(' ').collect();
        self.move_multiple_crates(
            instruction
                .get(1)
                .ok_or_else(|| anyhow!("Could not read count parameter"))?
                .parse()?,
            instruction
                .get(3)
                .ok_or_else(|| anyhow!("Could not read source parameter"))?
                .parse()?,
            instruction
                .get(5)
                .ok_or_else(|| anyhow!("Could not read target parameter"))?
                .parse()?,
            version,
        )?;
        Ok(())
    }
}
