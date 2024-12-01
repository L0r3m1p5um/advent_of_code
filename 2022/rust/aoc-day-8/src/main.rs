use color_eyre::eyre::eyre;
use nalgebra::{DMatrix, Matrix2, Rotation2};
use std::{
    fs::File,
    io::{BufRead, BufReader},
    path::Path,
    vec,
};

fn main() -> color_eyre::Result<()> {
    color_eyre::install()?;
    part2()?;
    Ok(())
}

fn init() -> color_eyre::Result<(String, (usize, usize))> {
    let path = Path::new("input.txt");
    let file = File::open(path)?;
    let mut row_count = 1;
    let input = BufReader::new(file)
        .lines()
        .map(|x| x.unwrap())
        .reduce(|x, y| {
            row_count += 1;
            return x + &y;
        })
        .ok_or_else(|| eyre!("Could not read input"))?;
    let input_length = input.len();
    Ok((input, (row_count, input_length / row_count)))
}

fn part2() -> color_eyre::Result<()> {
    let (input, (row_count, column_count)) = init()?;
    let mut trees: Vec<(usize, i16)> = input
        .chars()
        .map(|digit| (1, char::to_digit(digit, 10).unwrap() as i16))
        .collect();
    let matrix = DMatrix::from_iterator(row_count, column_count, (0..trees.len()).into_iter());
    matrix
        .row_iter()
        .map(|row| row.iter().cloned().collect())
        .for_each(|index_row: Vec<usize>| {
            calculate_score(&mut trees, &index_row).unwrap();
        });
    matrix
        .column_iter()
        .map(|column| column.iter().cloned().collect())
        .for_each(|index_row: Vec<usize>| {
            calculate_score(&mut trees, &index_row).unwrap();
        });
    println!("{}", trees.iter().map(|tree| tree.0).max().unwrap());

    Ok(())
}

fn part1() -> color_eyre::Result<()> {
    let (input, (row_count, column_count)) = init()?;
    let mut trees: Vec<(bool, i16)> = input
        .chars()
        .map(|digit| (false, char::to_digit(digit, 10).unwrap() as i16))
        .collect();
    let matrix = DMatrix::from_iterator(row_count, column_count, (0..trees.len()).into_iter());
    matrix
        .row_iter()
        .map(|row| row.iter().cloned().collect())
        .for_each(|mut index_row: Vec<usize>| {
            mark_visible_trees(&mut trees, &index_row);
            index_row.reverse();
            mark_visible_trees(&mut trees, &index_row)
        });
    matrix
        .column_iter()
        .map(|column| column.iter().cloned().collect())
        .for_each(|mut index_row: Vec<usize>| {
            mark_visible_trees(&mut trees, &index_row);
            index_row.reverse();
            mark_visible_trees(&mut trees, &index_row)
        });
    println!("visible trees: {}", trees.iter().filter(|x| x.0).count());
    Ok(())
}

fn mark_visible_trees(trees: &mut Vec<(bool, i16)>, indices: &Vec<usize>) {
    let mut max_height: i16 = -1;
    indices.iter().for_each(|&index| {
        let mut tree = trees.get_mut(index).unwrap();
        if tree.1 > max_height {
            max_height = tree.1;
            tree.0 = true;
        }
    });
}

fn calculate_score(trees: &mut Vec<(usize, i16)>, indices: &Vec<usize>) -> color_eyre::Result<()> {
    for i in 0..indices.len() {
        if i == 0 || i == indices.len() - 1 {
            let mut tree = trees
                .get_mut(*indices.get(i).unwrap())
                .ok_or_else(|| eyre!("Invalid index"))?;
            tree.0 = 0;
            continue;
        }

        let mut distance = 0;
        for j in (0..i).rev() {
            distance += 1;
            let other_height = trees
                .get(*indices.get(j).unwrap())
                .ok_or_else(|| eyre!("Invalid index"))?
                .1;
            let mut tree = trees
                .get_mut(*indices.get(i).unwrap())
                .ok_or_else(|| eyre!("Invalid index"))?;
            if other_height >= tree.1 || j == 0 {
                tree.0 *= distance;
                break;
            }
        }

        let mut distance = 0;
        for j in i + 1..trees.len() {
            distance += 1;
            let other_height = trees
                .get(*indices.get(j).unwrap())
                .ok_or_else(|| eyre!("Invalid index"))?
                .1;
            let mut tree = trees
                .get_mut(*indices.get(i).unwrap())
                .ok_or_else(|| eyre!("Invalid index"))?;
            if other_height >= tree.1 || j == indices.len() - 1 {
                tree.0 *= distance;
                break;
            }
        }
    }
    Ok(())
}
