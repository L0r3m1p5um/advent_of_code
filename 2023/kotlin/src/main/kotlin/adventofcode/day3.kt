package adventofcode.day3

import adventofcode.common.combinations
import adventofcode.common.readLines
import adventofcode.common.withCoordinates
import adventofcode.common.adjacent
import adventofcode.day3.ItemType.*

fun main() {
    println("Part 1")
    part1()
    println("Part 2")
    part2()
}

data class Item (
    val value: Char,
    val type: ItemType,
    val coordinates: Pair<Int, Int>
)

enum class ItemType {
    Digit, Empty, Symbol
}

fun readInput() = readLines("day3/input.txt")
    .map { it.toList().map { char -> char to when (char) {
        in '0'..'9' -> Digit
        '.' -> Empty
        else -> Symbol
    }
    }}.withCoordinates().map {
        it.map {
            (coord, item) ->
            Item(item.first, item.second, coord)
        }
    }

fun List<Item>.groupConsecutive(): List<List<Item>> =
    fold(mutableListOf<MutableList<Item>>())  { acc, next ->
        val previous = acc.lastOrNull()
        if (previous != null) {
            val (lastRow, lastCol) = acc.last().last().coordinates
            if (next.coordinates == lastRow to lastCol + 1) {
                acc.last().add(next)
                acc
            } else {
                acc.add(mutableListOf(next))
                acc
            }
        } else {
            acc.add(mutableListOf(next))
            acc
        }
    }

fun findNumbers(grid: List<List<Item>>): List<List<Item>> =
    grid.fold(listOf<Item>()) { acc, next ->
        acc + next.filter { it.type == Digit }
    }.groupConsecutive()

fun part1() {
    val grid = readInput()
    val result = findNumbers(grid).filter {number ->
        number.flatMap { digit ->
            grid.adjacent(digit.coordinates.first, digit.coordinates.second)
        }.any { it.type == Symbol }
    }.map {
        it.map(Item::value).joinToString("").toIntOrNull()!!
    }.sum()
    println(result)
}

fun part2() {
    val grid = readInput()
    val numbers = findNumbers(grid)
    val gears = grid.flatMap {row -> row.filter {
        it.value == '*'
    } }.associateWith {gear ->
        val adjacent = grid.adjacent(gear.coordinates.first, gear.coordinates.second)
        numbers.filter { number ->
            number.any {digit -> adjacent.contains(digit)}
        }.map { it.map(Item::value).joinToString("").toIntOrNull()!!}
    }.filter { (_, numbers) -> numbers.size == 2 }

    println(gears.values.map {
        it.fold(1) { acc, next -> acc * next}
    }.sum())
}