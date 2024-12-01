use color_eyre;
use color_eyre::eyre::eyre;
use rayon::prelude::*;
use std::{env, fs};

fn main() -> color_eyre::Result<()> {
    color_eyre::install()?;
    let args: Vec<String> = env::args().collect();
    let filename = args.get(1).ok_or(eyre!("Filename argument required"))?;
    let input = read_input(filename).unwrap();
    let node_map = expand_map(input);
    let total_risk = djikstra(node_map)?;
    println!("Result is {total_risk}");
    Ok(())
}

fn read_input(filename: &str) -> color_eyre::Result<NodeMap> {
    let input = fs::read_to_string(filename)?;
    let nodemap: Vec<Vec<Node>> = input
        .lines()
        .enumerate()
        .map(|(y, line)| {
            line.chars()
                .enumerate()
                .map(|(x, digit)| Node {
                    coordinates: (x, y),
                    risk: digit.to_string().parse().unwrap(),
                    total_risk: if (x, y) == (0, 0) { Some(0) } else { None },
                    visited: false,
                })
                .collect()
        })
        .collect();

    Ok(NodeMap {
        initial: (0, 0),
        destination: (nodemap.get(0).unwrap().len() - 1, nodemap.len() - 1),
        map: nodemap,
    })
}

fn djikstra(mut node_map: NodeMap) -> color_eyre::Result<u32> {
    let destination = node_map.destination.clone();
    while let Some(coords) = node_map.current_node() {
        let node = visit_node(&mut node_map, coords)?;
        if coords == destination {
            return node
                .total_risk
                .ok_or(eyre!("Destination node does not have total risk"));
        }
    }
    println!("{:?}", node_map);
    Err(eyre!(
        "Algorithm completed but destination node was not found"
    ))
}

fn visit_node(node_map: &mut NodeMap, coords: (usize, usize)) -> color_eyre::Result<Node> {
    let node = node_map
        .get_mut(coords)
        .ok_or(eyre!("Could not find node at coordinates {:?}", coords))?;
    node.visited = true;
    let node = node.clone();
    let neighbors: Vec<(usize, usize)> = node_map
        .unvisited_neighbors(coords)
        .par_iter()
        .map(|neigbor| neigbor.coordinates.clone())
        .collect();
    for neighbor_coords in neighbors {
        let neighbor = node_map.get_mut(neighbor_coords).ok_or(eyre!(
            "Could not get neighbor at coordinates {:?}",
            neighbor_coords
        ))?;
        match (node.total_risk, neighbor.total_risk) {
            (None, _) => Err(eyre!("Visited node does not have risk set")),
            (Some(_), None) => {
                neighbor.total_risk = Some(node.total_risk.unwrap() + neighbor.risk);
                Ok(())
            }
            (Some(current_total), Some(neighbor_total)) => {
                if neighbor_total > current_total + neighbor.risk {
                    neighbor.total_risk = Some(current_total + neighbor.risk)
                }
                Ok(())
            }
        }?;
    }
    Ok(node)
}

#[derive(Debug, PartialEq, Eq, PartialOrd, Ord, Clone)]
struct Node {
    coordinates: (usize, usize),
    risk: u32,
    total_risk: Option<u32>,
    visited: bool,
}

#[derive(Debug, PartialEq, Eq, PartialOrd, Ord, Clone)]
struct NodeMap {
    initial: (usize, usize),
    destination: (usize, usize),
    map: Vec<Vec<Node>>,
}

impl NodeMap {
    fn get(&self, (x, y): (usize, usize)) -> Option<&Node> {
        match self.map.get(y) {
            Some(row) => row.get(x),
            None => None,
        }
    }

    fn get_mut(&mut self, (x, y): (usize, usize)) -> Option<&mut Node> {
        match self.map.get_mut(y) {
            Some(row) => row.get_mut(x),
            None => None,
        }
    }

    fn unvisited_neighbors(&self, (x, y): (usize, usize)) -> Vec<&Node> {
        let x = x as isize;
        let y = y as isize;
        let candidates = vec![(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)];
        candidates
            .par_iter()
            .filter(|(cx, cy)| *cx >= 0 && *cy >= 0)
            .filter_map(|(cx, cy)| self.get((*cx as usize, *cy as usize)))
            .filter(|node| !node.visited)
            .collect()
    }

    fn current_node(&self) -> Option<(usize, usize)> {
        let result = self
            .map
            .par_iter()
            .map(|row| {
                row.par_iter()
                    .filter(|node| !node.visited && node.total_risk.is_some())
                    .map(|node| (node.coordinates, node.total_risk.unwrap()))
                    .collect()
            })
            .collect::<Vec<Vec<((usize, usize), u32)>>>()
            .into_iter()
            .fold(
                vec![],
                |mut acc: Vec<((usize, usize), u32)>, nodes: Vec<((usize, usize), u32)>| {
                    acc.append(&mut nodes.clone());
                    acc
                },
            )
            .into_iter()
            .fold(
                None,
                |acc: Option<((usize, usize), u32)>, node: ((usize, usize), u32)| match acc {
                    None => Some(node),
                    Some(prev_node) => {
                        if node.1 < prev_node.1 {
                            Some(node)
                        } else {
                            Some(prev_node)
                        }
                    }
                },
            );
        match result {
            None => None,
            Some((coords, _)) => Some(coords),
        }
    }
}

fn build_x_map(node_map: NodeMap) -> NodeMap {
    let new_map: Vec<Vec<Node>> = node_map
        .map
        .into_iter()
        .map(|row| {
            let mut result: Vec<Node> = vec![];
            for i in 0..5 {
                result.append(
                    &mut row
                        .clone()
                        .into_par_iter()
                        .map(|node| Node {
                            total_risk: if i == 0 { node.total_risk } else { None },
                            risk: ((node.risk - 1 + i) % 9) + 1,
                            visited: false,
                            coordinates: (
                                node.coordinates.0 + i as usize * row.len(),
                                node.coordinates.1,
                            ),
                        })
                        .collect(),
                )
            }
            result
        })
        .collect();
    NodeMap {
        initial: node_map.initial,
        destination: (new_map.get(0).unwrap().len() - 1, new_map.len() - 1),
        map: new_map,
    }
}

fn build_y_map(node_map: NodeMap) -> NodeMap {
    let new_map: Vec<Vec<Node>> = (0..5).into_iter().fold(vec![], |mut acc, i| {
        acc.append(
            &mut node_map
                .map
                .clone()
                .into_par_iter()
                .map(|row| {
                    row.into_iter()
                        .map(|node| Node {
                            total_risk: if i == 0 { node.total_risk } else { None },
                            visited: false,
                            coordinates: (
                                node.coordinates.0,
                                node.coordinates.1 + i * node_map.map.len(),
                            ),
                            risk: ((node.risk - 1 + i as u32) % 9) + 1,
                        })
                        .collect()
                })
                .collect(),
        );
        acc
    });
    NodeMap {
        initial: node_map.initial,
        destination: (new_map.get(0).unwrap().len() - 1, new_map.len() - 1),
        map: new_map,
    }
}

fn expand_map(node_map: NodeMap) -> NodeMap {
    build_y_map(build_x_map(node_map))
}
