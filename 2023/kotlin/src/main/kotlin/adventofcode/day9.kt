package adventofcode.day9

import adventofcode.common.readLines

fun main() {
    println("Part 1")
    part1()
    println("Part 2")
    part2()
}

fun parseInput() = readLines("day9/input.txt")
    .map {
        it.split(" ")
            .map { digit -> digit.toIntOrNull()!! }
    }

fun buildSequenceDifferences(line: List<Int>): List<List<Int>> {
    tailrec fun inner(acc: List<List<Int>>, line: List<Int>): List<List<Int>> {
        if (line.all { it == 0 }) return acc.plusElement(line) else {
            val nextRow = line.pairs().fold(listOf<Int>()) { acc, pair ->
                acc + (pair.second - pair.first)
            }
            return inner(acc.plusElement(line), nextRow)
        }
    }
    return inner(listOf(), line)
}

fun part1() {
    val result = parseInput().map(::buildSequenceDifferences)
        .map { history ->
            history.reversed().fold(0) { acc, row ->
                row.last() + acc
            }
        }.sum()

    println(result)
}

fun part2() {
    val result = parseInput().map(::buildSequenceDifferences).map { history ->
        history.reversed().fold(0) { acc, row -> row.first() - acc }
    }.sum()
    println(result)
}

fun <T> List<T>.pairs(): List<Pair<T, T>> =
    (0..<size - 1).fold(listOf()) { acc, i ->
        acc.plus(this[i] to this[i + 1])
    }
