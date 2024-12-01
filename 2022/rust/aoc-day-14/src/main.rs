fn main() {
    println!("Hello, world!");
}

fn part1() {
    let input = include_str!("input-test.txt");
}

struct Cave {
    cave: Vec<Vec<CaveBlock>>,
}

impl Cave {
    fn new(input: &str) -> Self {
        let paths: Vec<Vec<(i32, i32)>> = input
            .lines()
            .map(|line| {
                line.split(" -> ")
                    .map(|coords| {
                        let coords = coords.split(",");
                        (
                            coords.next().unwrap().parse::<i32>().unwrap(),
                            coords.next().unwrap().parse::<i32>().unwrap(),
                        )
                    })
                    .collect::<Vec<(i32, i32)>>()
            })
            .collect();
        let rocks = paths.iter().map(|path| {
            let rocks: Vec<(i32, i32)> = vec![];
            for i in 0..path.len() - 1 {
                let start = path.get(i).unwrap();
                let end = path.get(i + 1).unwrap();
                rocks.push(start.clone());
                let x_diff = start.0 - end.0;
                let y_diff = start.1 - end.1;
                match (x_diff, y_diff) {
                    (x,0) if x > 0 => {
                        let (start_x, start_y) = *start;
                        for j in 1..x+1 {
                            rocks.push((start_x + j, start_y));
                        } 
                    }
                }
            }
        });
    }
}

enum CaveBlock {
    Air,
    Sand,
    Stone,
    Source,
}
