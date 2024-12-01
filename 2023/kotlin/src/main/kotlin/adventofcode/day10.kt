package adventofcode.day10

import adventofcode.common.adjacent
import adventofcode.common.readLines
import adventofcode.common.withCoordinates
import adventofcode.day10.PipeType.*
import adventofcode.day10.Direction.*

fun main() {
    part1()
}

fun part1() {
    val grid = parseInput()
    val start = grid.flatten().find { it.type == Start }!!
    val second = grid.adjacent(start.coordinates.first, start.coordinates.second)
        .first { pipe -> pipe.enterFrom(start.coordinates) != null }
    var firstIteration = true
    val path = generateSequence(start to second) { (current, next) ->
        val coord = next.enterFrom(current.coordinates)
        if (coord == null) null else next to grid[coord.first][coord.second]
    }.takeWhile { (current, _) ->
        if (firstIteration) {
            firstIteration = false
            true
        } else current.type != Start }
        .map(Pair<Pipe,Pipe>::first).toList()

    println(path.size / 2)


}

fun parseInput() =
    readLines("day10/input.txt").map { line ->
        line.map { c ->
            when (c) {
                '|' -> NorthSouth
                '-' -> EastWest
                'L' -> NorthEast
                'J' -> NorthWest
                '7' -> SouthWest
                'F' -> SouthEast
                '.' -> Ground
                'S' -> Start
                else -> throw IllegalArgumentException("Pipe type not recognized: $c")
            }
        }
    }.withCoordinates().map { line ->
        line.map { (coord, type) ->
            Pipe(type, coord)
        }
    }

data class Pipe(val type: PipeType, val coordinates: Pair<Int, Int>) {
    fun enterFrom(entry: Pair<Int, Int>): Pair<Int, Int>? {
        return when (type to entry) {
            NorthSouth to coordinates.go(South) -> coordinates.go(North)
            NorthSouth to coordinates.go(North) -> coordinates.go(South)
            EastWest to coordinates.go(East) -> coordinates.go(West)
            EastWest to coordinates.go(West) -> coordinates.go(East)
            SouthEast to coordinates.go(South) -> coordinates.go(East)
            SouthEast to coordinates.go(East) -> coordinates.go(South)
            SouthWest to coordinates.go(West) -> coordinates.go(South)
            SouthWest to coordinates.go(South) -> coordinates.go(West)
            NorthEast to coordinates.go(North) -> coordinates.go(East)
            NorthEast to coordinates.go(East) -> coordinates.go(North)
            NorthWest to coordinates.go(North) -> coordinates.go(West)
            NorthWest to coordinates.go(West) -> coordinates.go(North)
            else -> null
        }
    }
}

enum class Direction {
    North,
    South,
    East,
    West
}

fun Pair<Int, Int>.go(direction: Direction) = when (direction) {
    North  -> first - 1 to second
    South -> first + 1 to second
    East -> first to second + 1
    West -> first to second - 1
}


enum class PipeType {
    Start,
    NorthSouth,
    EastWest,
    SouthEast,
    SouthWest,
    NorthEast,
    NorthWest,
    Ground,
}