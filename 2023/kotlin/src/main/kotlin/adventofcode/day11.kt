package adventofcode.day11

import adventofcode.common.combinations
import adventofcode.common.readLines
import adventofcode.common.withCoordinates
import adventofcode.day11.SpaceType.*
import java.lang.IllegalArgumentException
import kotlin.math.abs
import kotlin.math.exp

fun main() {
    println("Part 1")
    part1()
    println("Part 2")
    part2()
}

fun part1() {
    val grid = parseInput().expand().toSpace()
    val galaxies = grid.flatten().filter { it.type == Galaxy }

    println(
        galaxies.combinations()
            .map { (first, second) ->
                grid.distanceBetween(first, second, 2)
            }.sum() / 2
    )

}

fun part2() {
    val grid = parseInput().expand().toSpace()
    val galaxies = grid.flatten().filter { it.type == Galaxy }

    println(
        galaxies.combinations()
            .map { (first, second) ->
                grid.distanceBetween(first, second, 1000000)
            }.sum() / 2
    )
}

fun parseInput() =
    readLines("day11/input.txt").map { line ->
        line.map {
            when (it) {
                '.' -> Empty
                '#' -> Galaxy
                else -> throw IllegalArgumentException()
            }
        }.toList()
    }

fun List<List<SpaceType>>.expand(): List<List<SpaceType>> {
    val colIsEmpty = (0 until first().size).map { colIndex ->
        (0 until size).all { this[it][colIndex] == Empty }
    }
    val rowIsEmpty = map { row ->
        row.all { it == Empty }
    }

    val expandedColumns = map { row ->
        row.zip(colIsEmpty).fold(listOf<SpaceType>()) { acc, (space, isEmpty) ->
            if (isEmpty) {
                acc + Expanse
            } else {
                acc + space
            }
        }
    }
    return expandedColumns.zip(rowIsEmpty)
        .fold(listOf()) { acc, (row, isEmpty) ->
            if (isEmpty) acc.plusElement(List(row.size) { Expanse })
            else acc.plusElement(row)
        }
}

fun List<List<SpaceType>>.toSpace() = this.withCoordinates()
    .map { line ->
        line.map { (coord, type) -> Space(type, coord) }
    }

fun List<List<SpaceType>>.show() {
    forEach { line ->
        line.forEach { print(it) }
        println()
    }
}

fun List<List<Space>>.distanceBetween(first: Space, second: Space, expanseDistance: Int): Long {
    val (verticalDist, horizontalDist) = second.coordinates.first - first.coordinates.first to
            second.coordinates.second - first.coordinates.second
    val sign = { i: Int -> if (i == 0) 1 else i / abs(i) }

    val path =
        (1..abs(verticalDist)).map { first.coordinates.first + it * sign(verticalDist) to first.coordinates.second } +
                (1..abs(horizontalDist)).map {
                    first.coordinates.first + verticalDist to
                            first.coordinates.second + it * sign(horizontalDist)
                }
    return path.map { (row, column) ->
        this[row][column]
    }.fold(0L) { acc, space ->
        if (space.type == Expanse) acc + expanseDistance else acc + 1
    }
}


data class Space(
    val type: SpaceType,
    val coordinates: Pair<Int, Int>
)

enum class SpaceType {
    Galaxy {
        override fun toString() = "#"
    },
    Empty {
        override fun toString() = "."
    },
    Expanse {
        override fun toString() = "*"
    }
}