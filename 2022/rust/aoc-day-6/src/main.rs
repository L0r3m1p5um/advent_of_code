use std::collections::HashSet;

const TEST_INPUT: &str = "zcfzfwzzqfrljwzlrfnpqdbhtmscgvjw";
const INPUT: &str = include_str!("../input.txt");
const START_OF_PACKET_LENGTH: usize = 4;
const START_OF_MESSAGE_LENGTH: usize = 14;

fn main() {
    part1();
    part2();
}

fn part1() {
    let input = INPUT.clone();
    let mut marker = Marker::new(START_OF_PACKET_LENGTH);
    let (index, _) = input
        .chars()
        .enumerate()
        .find(|(index, item)| {
            marker.add(*item);
            marker.is_valid_marker()
        })
        .unwrap();
    println!("{}", index + 1);
}

fn part2() {
    let input = INPUT.clone();
    let mut marker = Marker::new(START_OF_MESSAGE_LENGTH);
    let (index, _) = input
        .chars()
        .enumerate()
        .find(|(index, item)| {
            marker.add(*item);
            marker.is_valid_marker()
        })
        .unwrap();
    println!("{}", index + 1);
}

struct Marker {
    last_four: Vec<char>,
    max_length: usize,
}

impl Marker {
    fn new(max_length: usize) -> Self {
        Marker {
            last_four: vec![],
            max_length,
        }
    }

    fn add(&mut self, item: char) {
        self.last_four.push(item);
        if self.last_four.len() > self.max_length {
            self.last_four.remove(0);
        }
    }

    fn is_valid_marker(&self) -> bool {
        self.last_four
            .clone()
            .into_iter()
            .collect::<HashSet<char>>()
            .len()
            == self.max_length
    }
}
