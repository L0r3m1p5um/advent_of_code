use std::{fs::File, path::Path, io::{BufReader, BufRead}};

fn main() {
    part2();
}

fn part1() {
    let path = Path::new("assignments.txt");
    let file = File::open(path).unwrap();
    let result = BufReader::new(file).lines().map(|line| {
        let line = line.unwrap();
        let mut ranges = line.split(",");
        (Assignment::new(ranges.next().unwrap()), Assignment::new(ranges.next().unwrap()))
    }).filter(|(x, y)| {
        x.contains(y) || y.contains(x)
    }).count();
    println!("{}", result);
}

fn part2() {
    let path = Path::new("assignments.txt");
    let file = File::open(path).unwrap();
    let result = BufReader::new(file).lines().map(|line| {
        let line = line.unwrap();
        let mut ranges = line.split(",");
        (Assignment::new(ranges.next().unwrap()), Assignment::new(ranges.next().unwrap()))
    }).filter(|(x, y)| {
        x.overlaps(y)
    }).count();
    println!("{}", result);
}

#[derive(Debug)]
struct Assignment {
    range_start: u8,
    range_end: u8,
}

impl Assignment {
    fn new(range: &str) -> Self {
        let mut range = range.split("-");
        Assignment {
            range_start: range.next().unwrap().parse().unwrap(),
            range_end: range.next().unwrap().parse().unwrap(),
        }
    }

    fn contains(&self, other: & Assignment) -> bool {
        self.range_start <= other.range_start && self.range_end >= other.range_end
    }

    fn overlaps(&self, other: & Assignment) -> bool {
        (self.range_start >= other.range_start && self.range_start <= other.range_end)
        || (self.range_end >= other.range_start && self.range_end <= other.range_end)
        || (other.range_start >= self.range_start && other.range_start <= self.range_end)
        || (other.range_end >= self.range_start && other.range_end <= self.range_end)
    }
}
