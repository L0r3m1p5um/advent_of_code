package adventofcode.day6

import adventofcode.common.readLines
import adventofcode.common.readText
import kotlin.math.floor
import kotlin.math.sqrt

fun main() {
    println("Part 1")
    part1()
    println("Part 2")
    part2()
}

fun part1() {
    val races = parsePart1()
    println(races.map { race ->
        (0..race.time).map { buttonPress ->
            calculateDistance(race.time, buttonPress)
        }.count {
            it > race.distanceRecord
        }
    }.fold(1) { acc, i -> acc * i })
}

fun part2() {
    val race = parsePart2()
    val (sol1, sol2)  = quadraticFormula(-1, race.time, -race.distanceRecord)
    println(sol2 - sol1)
}

fun parsePart1(): List<Race> {
    val input = readText("day6/input.txt").lines()
    val parseLine = { line: String ->
        line.split("\\s+".toRegex()).drop(1).map { it.toLongOrNull()!! }
    }
    return parseLine(input.first()).zip(parseLine(input.last())) { time, distance ->
        Race(time, distance)
    }
}

fun parsePart2(): Race {
    val input = readLines("day6/input.txt").toList()
    val parseLine = { line: String ->
        line.split("\\s+".toRegex()).drop(1).joinToString("").toLongOrNull()!!
    }
    return Race(
        parseLine(input.first()),
        parseLine(input.last())
    )
}

fun calculateDistance(raceLength: Long, buttonPress: Long) = (raceLength - buttonPress) * buttonPress

fun quadraticFormula(a: Long, b: Long, c: Long) =
    floor((-b + sqrt((b * b - 4 * a * c).toDouble())) / (2 * a).toDouble()).toLong() to
            floor((-b - sqrt((b * b - 4 * a * c).toDouble())) / (2 * a).toDouble()).toLong()

data class Race(
    val time: Long,
    val distanceRecord: Long
)