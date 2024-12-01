fn main() {
    part2();
}

fn part2() {
    let mut monkeys = monkeys();
    for _ in 0..10000 {
        monkeys = throw_items_round(monkeys);
    }
    println!(
        "{:?}",
        monkeys
            .iter()
            .map(|monkey| &monkey.items)
            .collect::<Vec<&Vec<usize>>>()
    );

    println!("{}", monkey_business(&monkeys));
}



fn monkey_business(monkeys: &Vec<Monkey>) -> usize {
    let mut inspections: Vec<usize> = monkeys.iter().map(|monkey| monkey.inspections).collect();
    inspections.sort();
    println!("inspections: {:?}", inspections);
    let length = inspections.len();
    let most_active = inspections.get(length - 1).unwrap();
    let second_most_active = inspections.get(length - 2).unwrap();
    most_active * second_most_active
}

fn throw_items_round(mut monkeys: Vec<Monkey>) -> Vec<Monkey> {
    for i in 0..monkeys.len() {
        let monkey = monkeys.get_mut(i).unwrap();
        let items = monkey.throw_all_items();
        for item in items {
            let target_monkey = monkeys.get_mut(item.1).unwrap();
            target_monkey.give_item(item.0);
        }
    }
    monkeys
}

struct Monkey {
    items: Vec<usize>,
    operation: Box<dyn Fn(usize) -> usize>,
    test: Box<dyn Fn(usize) -> usize>,
    inspections: usize,
}

impl Monkey {
    fn give_item(&mut self, item: usize) {
        self.items.push(item);
    }
    fn throw_next_item(&mut self) -> Option<(usize, usize)> {
        if self.items.len() == 0 {
            return None;
        }

        self.inspections += 1;
        let item = self.items.remove(0);
        let item = (self.operation)(item);
        // Wrong: let item = item % 9699690;
        let item = item % 9699690;
        let item_target = (self.test)(item);
        Some((item, item_target))
    }

    fn throw_all_items(&mut self) -> Vec<(usize, usize)> {
        let mut items = vec![];
        while let Some(item) = self.throw_next_item() {
            items.push(item);
        }
        items
    }
}

fn test_monkeys() -> Vec<Monkey> {
    let monkeys = vec![
        Monkey {
            items: vec![79, 98],
            operation: Box::new(|x| x * 19),
            test: Box::new(|x| match x % 23 == 0 {
                true => 2,
                false => 3,
            }),
            inspections: 0,
        },
        Monkey {
            items: vec![54, 65, 75, 74],
            operation: Box::new(|x| x + 6),
            test: Box::new(|x| match x % 19 == 0 {
                true => 2,
                false => 0,
            }),
            inspections: 0,
        },
        Monkey {
            items: vec![79, 60, 97],
            operation: Box::new(|x| x * x),
            test: Box::new(|x| match x % 13 == 0 {
                true => 1,
                false => 3,
            }),
            inspections: 0,
        },
        Monkey {
            items: vec![74],
            operation: Box::new(|x| x + 3),
            test: Box::new(|x| match x % 17 == 0 {
                true => 0,
                false => 1,
            }),
            inspections: 0,
        },
    ];
    monkeys
}

fn monkeys() -> Vec<Monkey> {
    let monkeys = vec![
        Monkey {
            items: vec![84, 72, 58, 51],
            operation: Box::new(|x| x * 3),
            test: Box::new(|x| match x % 13 == 0 {
                true => 1,
                false => 7,
            }),
            inspections: 0,
        },
        Monkey {
            items: vec![88, 58, 58],
            operation: Box::new(|x| x + 8),
            test: Box::new(|x| match x % 2 == 0 {
                true => 7,
                false => 5,
            }),
            inspections: 0,
        },
        Monkey {
            items: vec![93, 82, 71, 77, 83, 53, 71, 89            ],
            operation: Box::new(|x| x * x),
            test: Box::new(|x| match x % 7 == 0 {
                true => 3,
                false => 4,
            }),
            inspections: 0,
        },
        Monkey {
            items: vec![81, 68, 65, 81, 73, 77, 96],
            operation: Box::new(|x| x + 2),
            test: Box::new(|x| match x % 17 == 0 {
                true => 4,
                false => 6,
            }),
            inspections: 0,
        },
        Monkey {
            items: vec![75, 80, 50, 73, 88],
            operation: Box::new(|x| x + 3),
            test: Box::new(|x| match x % 5 == 0 {
                true => 6,
                false => 0,
            }),
            inspections: 0,
        },
        Monkey {
            items: vec![59, 72, 99, 87, 91, 81],
            operation: Box::new(|x| x * 17 ),
            test: Box::new(|x| match x % 11 == 0 {
                true => 2,
                false => 3,
            }),
            inspections: 0,
        },
        Monkey {
            items: vec![86, 69],
            operation: Box::new(|x| x + 6 ),
            test: Box::new(|x| match x % 3 == 0 {
                true => 1,
                false => 0,
            }),
            inspections: 0,
        },
        Monkey {
            items: vec![91],
            operation: Box::new(|x| x + 1 ),
            test: Box::new(|x| match x % 19 == 0 {
                true => 2,
                false => 5,
            }),
            inspections: 0,
        },
    ];
    monkeys
}
