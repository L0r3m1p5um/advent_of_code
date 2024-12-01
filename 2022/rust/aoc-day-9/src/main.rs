#![feature(split_array)]

use color_eyre::eyre::eyre;
use itertools::Itertools;
use std::collections::HashSet;

fn main() -> color_eyre::Result<()> {
    part2()?;
    Ok(())
}

fn part1() -> color_eyre::Result<()> {
    let input = include_str!("input.txt");
    let mut rope = Rope::new(2);
    input
        .lines()
        .map(|line| parse_instruction(line).unwrap())
        .for_each(|(direction, distance)| {
            rope.move_rope(direction, distance).unwrap();
        });
    println!("{}", rope.tail_history.len());
    Ok(())
}

fn part2() -> color_eyre::Result<()> {
    let input = include_str!("input.txt");
    let mut rope = Rope::new(10);
    input
        .lines()
        .map(|line| parse_instruction(line).unwrap())
        .for_each(|(direction, distance)| {
            rope.move_rope(direction, distance).unwrap();
        });
    println!("{}", rope.tail_history.len());
    Ok(())
}

enum Direction {
    Right,
    Left,
    Up,
    Down,
}

fn parse_instruction(instruction: &str) -> color_eyre::Result<(Direction, i32)> {
    //println!("Instruction: {}", instruction);
    let mut instruction = instruction.split(' ');
    let (direction, distance) = (
        instruction
            .next()
            .ok_or_else(|| eyre!("Missing argument"))?,
        instruction
            .next()
            .ok_or_else(|| eyre!("Missing argument"))?,
    );
    let direction = match direction {
        "R" => Direction::Right,
        "L" => Direction::Left,
        "U" => Direction::Up,
        "D" => Direction::Down,
        _ => return Err(eyre!("Invalid direction code")),
    };
    let distance: i32 = distance.parse()?;
    Ok((direction, distance))
}

#[derive(Debug)]
struct Rope {
    knots: Vec<(i32, i32)>,
    tail_history: HashSet<(i32, i32)>,
}

impl Rope {
    fn new(length: usize) -> Self {
        Rope {
            knots: vec![(0, 0); length],
            tail_history: HashSet::new(),
        }
    }

    fn head_mut(&mut self) -> color_eyre::Result<&mut (i32, i32)> {
        Ok(self
            .knots
            .first_mut()
            .ok_or_else(|| eyre!("Could not get head"))?)
    }

    fn tail(&self) -> color_eyre::Result<&(i32, i32)> {
        Ok(self
            .knots
            .last()
            .ok_or_else(|| eyre!("Could not get tail"))?)
    }

    fn move_rope(&mut self, direction: Direction, distance: i32) -> color_eyre::Result<()> {
        for x in 0..distance {
            //println!("Iteration: {}", x + 1);
            let mut head = self.head_mut()?;
            match direction {
                Direction::Right => head.0 += 1,
                Direction::Left => head.0 -= 1,
                Direction::Up => head.1 += 1,
                Direction::Down => head.1 -= 1,
            }
            self.drag_tail()?;
            //self.draw(60, 60, (29, 29));
        }
        Ok(())
    }

    fn draw(&self, height: usize, width: usize, start: (usize, usize)) {
        let mut grid = vec![".".to_string(); width * height];
        let rope = self.knots.clone();
        let mut rope: Vec<(usize, usize)> = rope
            .iter()
            .map(|(x, y)| ((*x + start.0 as i32) as usize, (*y + start.1 as i32) as usize))
            .collect();
        let start_square = grid
            .get_mut(start.0 + (width * (height - start.1)))
            .unwrap();
        *start_square = "S".to_string();

        rope.reverse();
        let length = rope.len();
        for (index, knot) in rope.iter().enumerate() {
            let square = grid.get_mut(knot.0 + (width * (height - knot.1))).unwrap();
            match index {
                0 => {
                    *square = "T".to_string();
                }
                x if x == length - 1 => {
                    *square = "H".to_string();
                }
                _ => {
                    let value = (length - index - 1).to_string();
                    *square = value;
                }
            }
        }

        grid.iter()
            .batching(|it| {
                let next_line = it.take(width).cloned().join(" ");
                match next_line.len() {
                    0 => None,
                    _ => Some(next_line),
                }
            })
            .for_each(|line| println!("{}", line));
    }

    fn drag_tail(&mut self) -> color_eyre::Result<()> {
        let length = self.knots.len();
        let (mut head, mut tail) = self.knots.split_first_mut().unwrap();
        for _ in 1..length {
            let (follower, tail_new) = tail.split_first_mut().unwrap();
            tail = tail_new;
            follow(head, follower)?;
            head = follower;
        }
        self.tail_history.insert(self.tail()?.clone());
        Ok(())
    }
}

fn follow(head: &(i32, i32), tail: &mut (i32, i32)) -> color_eyre::Result<()> {
    //println!("head: {:?}, tail:{:?}", head, tail);
    let x_delta = head.0 - tail.0;
    let y_delta = head.1 - tail.1;
    match (x_delta, y_delta) {
        (2, -1|0|1) => {
            *tail = (head.0 - 1, head.1);
        }
        (-2,-1|0|1) => {
            *tail = (head.0 + 1, head.1);
        }
        (-1|0|1, 2) => {
            *tail = (head.0, head.1 - 1);
        }
        (-1|0|1, -2) => {
            *tail = (head.0, head.1 + 1);
        }
        (2,2) => {
            *tail = (tail.0 + 1, tail.1 + 1)
        }
        (2,-2) => {
            *tail = (tail.0 + 1, tail.1 - 1)
        }
        (-2,2) => {
            *tail = (tail.0 - 1, tail.1 + 1)
        }
        (-2, -2) => {
            *tail = (tail.0 - 1, tail.1 - 1)
        }
        (-1 | 0 | 1, -1 | 0 | 1) => {}
        _ => return Err(eyre!("Invalid tail distance")),
    };
    Ok(())
}
