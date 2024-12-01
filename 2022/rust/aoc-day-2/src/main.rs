use std::{
    fs::File,
    io::{BufRead, BufReader},
    path::Path,
};

fn main() {
    let path = Path::new("strategy-guide.txt");
    let file = File::open(path).unwrap();
    let total_score: i32 = BufReader::new(file)
        .lines()
        .map(|line| parse_line_part_2(&line.unwrap()).total_score())
        .sum();
    println!("{}", total_score)
}

#[derive(Debug, Copy, Clone)]
enum Choice {
    Rock,
    Paper,
    Scissors,
}

#[derive(Debug)]
enum RoundResult {
    Win,
    Loss,
    Draw,
}

fn parse_line_part_1(line: &str) -> Round {
    let mut result = line.split(" ").take(2).map(|code| match code {
        "A" | "X" => Choice::Rock,
        "B" | "Y" => Choice::Paper,
        "C" | "Z" => Choice::Scissors,
        x => panic!("Invalid input {}", x),
    });
    Round {
        opponent_choice: result.next().unwrap(),
        my_choice: result.next().unwrap(),
    }
}

fn parse_line_part_2(line: &str) -> Round {
    let mut codes = line.split(" ");
    let opponent_choice = codes
        .next()
        .map(|code| match code {
            "A" => Choice::Rock,
            "B" => Choice::Paper,
            "C" => Choice::Scissors,
            x => panic!("Invalid input {}", x),
        })
        .unwrap();
    let desired_result = codes
        .next()
        .map(|code| match code {
            "X" => RoundResult::Loss,
            "Y" => RoundResult::Draw,
            "Z" => RoundResult::Win,
            x => panic!("Invalid code for desired result: {}", x),
        })
        .unwrap();

    match (opponent_choice, desired_result) {
        (x, RoundResult::Draw) => Round {
            my_choice: x.clone(),
            opponent_choice: x,
        },
        (Choice::Rock, RoundResult::Loss) => Round {
            my_choice: Choice::Scissors,
            opponent_choice: Choice::Rock,
        },
        (Choice::Paper, RoundResult::Loss) => Round {
            my_choice: Choice::Rock,
            opponent_choice: Choice::Paper,
        },
        (Choice::Scissors, RoundResult::Loss) => Round {
            my_choice: Choice::Paper,
            opponent_choice: Choice::Scissors,
        },
        (Choice::Rock, RoundResult::Win) => Round {
            my_choice: Choice::Paper,
            opponent_choice: Choice::Rock,
        },
        (Choice::Paper, RoundResult::Win) => Round {
            my_choice: Choice::Scissors,
            opponent_choice: Choice::Paper,
        },
        (Choice::Scissors, RoundResult::Win) => Round {
            my_choice: Choice::Rock,
            opponent_choice: Choice::Scissors,
        },
    }
}

#[derive(Debug)]
struct Round {
    my_choice: Choice,
    opponent_choice: Choice,
}

impl Round {
    fn result_score(&self) -> i32 {
        match (&self.my_choice, &self.opponent_choice) {
            (Choice::Rock, Choice::Scissors) => 6,
            (Choice::Paper, Choice::Rock) => 6,
            (Choice::Scissors, Choice::Paper) => 6,
            (Choice::Rock, Choice::Paper) => 0,
            (Choice::Paper, Choice::Scissors) => 0,
            (Choice::Scissors, Choice::Rock) => 0,
            (_, _) => 3,
        }
    }

    fn choice_score(&self) -> i32 {
        match self.my_choice {
            Choice::Rock => 1,
            Choice::Paper => 2,
            Choice::Scissors => 3,
        }
    }

    fn total_score(&self) -> i32 {
        self.result_score() + self.choice_score()
    }
}
