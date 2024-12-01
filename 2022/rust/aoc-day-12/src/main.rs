use std::collections::{HashMap, HashSet};

use itertools::Itertools;

fn main() {
    part1();
}

fn part1() {
    let map = include_str!("input.txt");
    let mut map = Map::new(map);
    map.find_valid_paths();
    map.find_path_to_end();
    println!("{}", map.steps);
    map.draw_path(map.end).unwrap();
}

#[derive(Debug)]
struct Cell {
    elevation: u8,
    valid_paths: Vec<Direction>,
    visited: bool,
}

impl Cell {
    fn new(elevation: char) -> Self {
        let elevation = match elevation {
            'S' => 0,
            'E' => 27,
            x => x as u8 - 0x60,
        };
        Cell {
            elevation,
            valid_paths: vec![],
            visited: false,
        }
    }
}

#[derive(Debug)]
struct Map {
    cells: Vec<Vec<Cell>>,
    start: (usize, usize),
    end: (usize, usize),
    steps: usize,
    next_cells: HashSet<(usize, usize)>,
    paths: HashMap<(usize, usize), (usize, usize)>,
}

impl Map {
    fn new(map: &str) -> Self {
        let mut start = (0, 0);
        let mut end = (0, 0);
        let mut x = 0;
        let mut y = 0;
        let cells = map
            .lines()
            .map(|line| {
                let row = line
                    .chars()
                    .map(|elevation| {
                        let mut cell = Cell::new(elevation);
                        if cell.elevation == 0 {
                            cell.visited = true;
                            start = (x, y);
                        } else if cell.elevation == 27 {
                            end = (x, y);
                        }
                        x += 1;
                        cell
                    })
                    .collect::<Vec<Cell>>();
                y += 1;
                x = 0;
                row
            })
            .collect();
        let mut next_cells = HashSet::new();
        next_cells.insert(start);
        Map {
            cells,
            start,
            end,
            steps: 0,
            next_cells,
            paths: HashMap::new(),
        }
    }

    fn find_path_to_end(&mut self) {
        while !self.next_cells.contains(&self.end) {
            println!("{}", self.steps);
            self.step_path();
            if self.steps < 50 {
                self.draw();
            }
        }
    }

    fn step_path(&mut self) {
        let mut next_cells = HashSet::new();
        let mut paths: Vec<((usize, usize), (usize, usize))> = vec![];
        for cell_coord in &self.next_cells {
            let cell = self.get_cell(*cell_coord);
            for direction in &cell.valid_paths {
                let next_cell = match direction {
                    Direction::Down => (cell_coord.0, cell_coord.1 + 1),
                    Direction::Up => (cell_coord.0, cell_coord.1 - 1),
                    Direction::Left => (cell_coord.0 - 1, cell_coord.1),
                    Direction::Right => (cell_coord.0 + 1, cell_coord.1),
                };
                if !self.get_cell(next_cell).visited {
                    if !self.paths.contains_key(&next_cell) {
                        paths.push((next_cell, *cell_coord));
                    }
                    next_cells.insert(next_cell);
                }
            }
        }
        if next_cells.len() == 0 {
            panic!("There are no cells to move to");
        }
        next_cells.iter().for_each(|coord| {
            let cell = self.get_cell_mut(*coord);
            cell.visited = true;
        });
        for (next, previous) in paths {
            self.paths.insert(next, previous);
        }
        self.next_cells = next_cells;
        self.steps += 1;
    }

    fn find_valid_paths(&mut self) {
        let row_len = self.cells.get(0).unwrap().len();
        let col_len = self.cells.len();
        for (x, y) in (0..row_len).cartesian_product(0..col_len) {
            let mut valid_paths = vec![];
            let cell = self.get_cell((x, y));
            if x > 0 {
                let cell2 = self.get_cell((x - 1, y));
                if cell2.elevation <= cell.elevation + 1 {
                    valid_paths.push(Direction::Left);
                }
            }
            if x < self.cells.get(0).unwrap().len() - 1 {
                let cell2 = self.get_cell((x + 1, y));
                if cell2.elevation <= cell.elevation + 1 {
                    valid_paths.push(Direction::Right);
                }
            }
            if y > 0 {
                let cell2 = self.get_cell((x, y - 1));
                if cell2.elevation <= cell.elevation + 1 {
                    valid_paths.push(Direction::Up);
                }
            }
            if y < self.cells.len() - 1 {
                let cell2 = self.get_cell((x, y + 1));
                if cell2.elevation <= cell.elevation + 1 {
                    valid_paths.push(Direction::Down);
                }
            }
            let cell = self.get_cell_mut((x, y));
            cell.valid_paths = valid_paths;
        }
        println!("Completed cell path marking");
    }

    fn get_cell(&self, coordinates: (usize, usize)) -> &Cell {
        self.cells
            .get(coordinates.1)
            .unwrap()
            .get(coordinates.0)
            .unwrap()
    }

    fn get_cell_mut(&mut self, coordinates: (usize, usize)) -> &mut Cell {
        self.cells
            .get_mut(coordinates.1)
            .unwrap()
            .get_mut(coordinates.0)
            .unwrap()
    }

    fn path_to_coord(&self, coords: (usize, usize)) -> Option<Vec<(usize, usize)>> {
        let mut coords = Some(&coords);
        let mut path: Vec<(usize, usize)> = vec![];
        while coords != None {
            match coords {
                Some(x) => {
                    path.push(*x);
                    coords = self.paths.get(x);
                }
                None => return None,
            }
        }
        path.reverse();
        match path.first() {
            Some(&x) if x == self.start => Some(path),
            _ => None,
        }
    }

    fn draw(&self) {
        let mut row_index = 0;
        for row in &self.cells {
            let map_row: String = row
                .iter()
                .enumerate()
                .map(|(col_index, elevation)| {
                    if self.next_cells.contains(&(col_index, row_index)) {
                        'X'
                    } else if self.get_cell((col_index, row_index)).visited {
                        'O'
                    } else {
                        match elevation.elevation {
                            0 => 'S',
                            27 => 'E',
                            x => (x + 0x60) as char,
                        }
                    }
                })
                .collect();
            println!("{}", map_row);
            row_index += 1;
        }
    }

    fn draw_path(&self, destination: (usize, usize)) -> Result<(), ()> {
        let mut row_index = 0;
        if let Some(path) = self.path_to_coord(destination) {
            for row in &self.cells {
                let map_row: String = row
                    .iter()
                    .enumerate()
                    .map(|(col_index, elevation)| {
                        if path.contains(&(col_index, row_index)) {
                            'X'
                        } else {
                            match elevation.elevation {
                                0 => 'S',
                                27 => 'E',
                                x => (x + 0x60) as char,
                            }
                        }
                    })
                    .collect();
                println!("{}", map_row);
                row_index += 1;
            }
            Ok(())
        } else {
            println!("No path exists to target");
            Err(())
        }
    }
}

#[derive(Debug)]
enum Direction {
    Up,
    Down,
    Left,
    Right,
}
