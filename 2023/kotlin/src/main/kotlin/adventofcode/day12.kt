package adventofcode.day12

import adventofcode.common.readLines
import adventofcode.day12.Spring.*
import arrow.core.memoize
import kotlin.system.measureTimeMillis

fun main() {
    println("Part 1")
    part1()
}

fun part1() {
    val elapsed = measureTimeMillis {
        println(parseInput().map { (springs, groups) ->
            (springs to groups).possibleCombinations().count { it.brokenGroups() == groups }
        }.sum())
    }
    println(elapsed)
}

fun part2() {
    val elapsed = measureTimeMillis {
        println(parseInputPart2().map { (springs, groups) ->
            val result = (springs to groups).possibleCombinations().count { it.brokenGroups() == groups }
            println("Row complete")
            result
        }.sum())
    }
    println(elapsed)
}



val parseSpring = { c: Char ->
    when (c) {
        '.' -> Operational
        '#' -> Broken
        '?' -> Unknown
        else -> throw IllegalArgumentException()
    }
}

fun parseInput() : List<Pair<List<Spring>, List<Int>>> {
    return readLines("day12/input.txt").map {line ->
        val parts = line.split(" ")
        parts.first().map(parseSpring) to
                parts.last().split(",").map(String::toInt)
    }
}

fun parseInputPart2() : List<Pair<List<Spring>, List<Int>>> {

    return readLines("day12/example.txt").map {line ->
        val parts = line.split(" ")
        val springs = List(5) {parts.first()}.joinToString("?").map(parseSpring)
        val groups = (List(5) { parts.last() }).joinToString(",").split(",").map(String::toInt)
        springs to groups
    }
}

fun List<Spring>.brokenGroups() = fold(listOf<List<Spring>>(listOf())) { acc, spring ->
    if (spring == Broken) acc.dropLast(1).plusElement(acc.last() + spring)
    else acc.plusElement(listOf())
}.map { it.size }.filter { it != 0 }

fun Pair<List<Spring>, List<Int>>.possibleCombinations(): List<List<Spring>> {
    val (springs, groups) = this
    val remainingBroken= groups.sum() - springs.count { it == Broken}
    val unknownIndices = springs.mapIndexedNotNull { index, spring ->
        if (spring == Unknown) index else null
    }
    val combinations = generateCombinationsMemoized(remainingBroken, unknownIndices.size)
    val result = combinations.map {combination ->
        val unknownMap = unknownIndices.zip(combination).associate { it }
        springs.mapIndexed { index, spring ->
            if (spring == Unknown) unknownMap.getValue(index) else spring
        }
    }
    return result

}

fun generateCombinations(broken: Int, total: Int): List<List<Spring>> {
    fun genCombinationsInner(current: List<List<Spring>>, broken: Int, operational: Int): List<List<Spring>> {
        if (broken == 0 && operational == 0) return current
        val nextBroken = if (broken > 0) {
            genCombinationsInner(current.map { it + Broken}, broken - 1, operational)
        } else {
            listOf()
        }
        val nextOperational = if (operational > 0) {
            genCombinationsInner(current.map { it + Operational}, broken, operational - 1)
        } else {
            listOf()
        }
        return nextBroken + nextOperational
    }
    return genCombinationsInner(listOf(listOf()), broken, total - broken)
}

val generateCombinationsMemoized = ::generateCombinations.memoize()

enum class Spring {
    Operational, Broken, Unknown
}