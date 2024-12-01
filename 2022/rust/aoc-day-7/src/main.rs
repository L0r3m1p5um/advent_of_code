use color_eyre::{eyre::eyre, Result};
use std::{
    cell::RefCell,
    collections::HashMap,
    fs::File,
    io::{BufRead, BufReader},
    path::Path,
    rc::Rc,
    vec,
};

fn main() -> Result<()> {
    color_eyre::install().unwrap();
    part2()?;
    Ok(())
}

fn part1() -> Result<()> {
    let path = Path::new("commands.txt");
    let file = File::open(path)?;
    let mut shell = Shell::new();
    BufReader::new(file)
        .lines()
        .for_each(|command| shell.execute_command(&command.unwrap()).unwrap());
    println!("{:?}", shell);
    println!(
        "{:?}",
        shell
            .directory_sizes()
            .into_iter()
            .filter(|&x| x <= 100000)
            .sum::<usize>()
    );

    Ok(())
}

fn part2() -> Result<()> {
    let path = Path::new("commdands.txt");
    let file = File::open(path)?;
    let mut shell = Shell::new();
    BufReader::new(file)
        .lines()
        .for_each(|command| shell.execute_command(&command.unwrap()).unwrap());

    let target_size = 30000000 - (70000000 - shell.size_at_path(vec![])?);

    println!(
        "{:?}",
        shell
            .directory_sizes()
            .into_iter()
            .filter(|&x| x >= target_size)
            .min()
    );

    Ok(())
}

#[derive(Debug)]
struct Shell {
    cwd: Vec<String>,
    root_dir: Rc<RefCell<FsItem>>,
    valid_paths: Vec<Vec<String>>,
}

impl Shell {
    fn new() -> Self {
        Shell {
            cwd: vec![],
            root_dir: Rc::new(RefCell::new(FsItem::Directory(Rc::new(RefCell::new(
                HashMap::new(),
            ))))),
            valid_paths: vec![vec![]],
        }
    }
    fn cd(&mut self, arg: &str) {
        match arg {
            "/" => self.cwd = vec![],
            ".." => {
                self.cwd.pop();
            }
            dir => self.cwd.push(dir.to_string()),
        }
    }

    fn size_at_path(&self, path: Vec<String>) -> Result<usize> {
        self.root_dir.borrow().size_at_path(path)
    }

    fn create(&mut self, name: &str, item: FsItem) -> Result<()> {
        match item {
            FsItem::Directory(_) => {
                let mut new_path = self.cwd.clone();
                new_path.push(name.to_string());
                self.valid_paths.push(new_path);
            }
            _ => {}
        }
        self.root_dir
            .borrow_mut()
            .create(self.cwd.clone(), name, item)
    }

    fn directory_sizes(&self) -> Vec<usize> {
        self.valid_paths
            .iter()
            .map(|path| self.size_at_path(path.clone()).unwrap())
            .collect()
    }

    fn execute_command(&mut self, command: &str) -> Result<()> {
        let command: Vec<&str> = command.split(' ').collect();
        match command.len() {
            2 => match (command.get(0).clone(), command.get(1).clone()) {
                (Some(&"$"), Some(&"ls")) => Ok(()),
                (Some(&"dir"), Some(name)) => Ok(self.create(
                    name,
                    FsItem::Directory(Rc::new(RefCell::new(HashMap::new()))),
                )?),
                (Some(size), Some(name)) => match size.parse::<usize>() {
                    Ok(size) => self.create(name, FsItem::File(size)),
                    Err(x) => Err(eyre!("Invalid size: {}", size)),
                },
                command => Err(eyre!("Invalid input: {:?}", command)),
            },
            3 => {
                match (
                    command.get(0).clone(),
                    command.get(1).clone(),
                    command.get(2).clone(),
                ) {
                    (Some(&"$"), Some(&"cd"), Some(name)) => Ok(self.cd(name)),
                    _ => Err(eyre!("Invalid arguments")),
                }
            }
            _ => Err(eyre!("Too many arguments")),
        }
    }
}

#[derive(Debug)]
enum FsItem {
    Directory(Rc<RefCell<HashMap<String, FsItem>>>),
    File(usize),
}

impl FsItem {
    fn size(&self) -> usize {
        match self {
            FsItem::File(size) => *size,
            FsItem::Directory(contents) => {
                contents.borrow().iter().map(|(_, item)| item.size()).sum()
            }
        }
    }

    pub fn size_at_path(&self, mut path: Vec<String>) -> Result<usize> {
        if path.len() == 0 {
            Ok(self.size())
        } else {
            match self {
                FsItem::File(_) => return Err(eyre!("Cannot get subpath of file")),
                FsItem::Directory(contents) => {
                    let next_dir = path.remove(0);
                    contents
                        .borrow()
                        .get(&next_dir)
                        .ok_or_else(|| eyre!("Directory {} does not exist", next_dir))?
                        .size_at_path(path)
                }
            }
        }
    }

    fn add_content(&mut self, name: &str, item: FsItem) -> Result<()> {
        match self {
            FsItem::File(_) => Err(eyre!("Can't add item to file")),
            FsItem::Directory(content) => {
                if !content.borrow().contains_key(name) {
                    content.borrow_mut().insert(name.to_string(), item);
                };
                Ok(())
            }
        }
    }

    fn create(&mut self, mut path: Vec<String>, name: &str, item: FsItem) -> Result<()> {
        if path.len() == 0 {
            self.add_content(name, item)?;
            Ok(())
        } else {
            let next_dir = path.remove(0);
            match self {
                FsItem::File(_) => return Err(eyre!("Invalid path")),
                FsItem::Directory(contents) => contents
                    .borrow_mut()
                    .get_mut(&next_dir)
                    .ok_or_else(|| eyre!("Invalid path"))?
                    .create(path, name, item)?,
            };
            Ok(())
        }
    }
}
