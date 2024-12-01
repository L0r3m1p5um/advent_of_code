use itertools::Itertools;
use std::{
    collections::HashSet,
    fs::File,
    io::{BufRead, BufReader},
    path::Path,
};

fn main() {
    let path = Path::new("input.txt");
    let file = File::open(path).unwrap();
    let lines = BufReader::new(file).lines();

    let priority_sum = lines
        .map(|line| Rucksack::new(&line.unwrap()).item_types())
        .batching(|it| {
            it.take(3)
                .reduce(|x, y| x.intersection(&y).map(|x| *x).collect())
        })
        .map(|codes| codes.iter().map(|code| priority(code)).sum::<u32>())
        .sum::<u32>();
    println!("{}", priority_sum);
}

fn total_priorities(reader: BufReader<File>) {
    let priority_sum: u32 = reader
        .lines()
        .map(|line| {
            let rucksack = Rucksack::new(&line.unwrap());
            rucksack
                .shared_items()
                .iter()
                .map(|code| priority(code))
                .sum::<u32>()
        })
        .sum();
    println!("{}", priority_sum);
}

fn priority(item: &char) -> u32 {
    if !item.is_ascii_alphabetic() {
        panic!("Invalid input");
    }
    let code: u32 = item.clone().into();
    if code < 0x60 {
        code - 0x40 + 26
    } else {
        code - 0x60
    }
}

#[derive(Debug)]
struct Rucksack {
    first_compartment: Vec<char>,
    second_compartment: Vec<char>,
}

impl Rucksack {
    fn new(line: &str) -> Self {
        let chars: Vec<char> = line.chars().collect();
        let (first_compartment, second_compartment) = chars.split_at(chars.len() / 2);
        Rucksack {
            first_compartment: first_compartment.into(),
            second_compartment: second_compartment.into(),
        }
    }

    fn item_types(&self) -> HashSet<char> {
        let first: HashSet<&char> = self.first_compartment.iter().collect();
        let second: HashSet<&char> = self.second_compartment.iter().collect();
        first.union(&second).cloned().map(|x| *x).collect()
    }

    fn shared_items(&self) -> HashSet<char> {
        let first: HashSet<&char> = self.first_compartment.iter().collect();
        let second: HashSet<&char> = self.second_compartment.iter().collect();
        first
            .intersection(&second)
            .cloned()
            .map(|x| *x)
            .collect::<HashSet<char>>()
    }
}
