package adventofcode.day8

import adventofcode.common.readLines
import adventofcode.day8.Direction.*
import java.nio.file.Path

fun main() {
    // println("Part 1")
    // part1()
    println("Part 2")
    part2()
}

fun part1() {
    val (directions, nodeMap) = parseInput()
    println(directions.repeating().runningFold(0 to "AAA") { (index, node), direction ->
        index + 1 to (nodeMap.getValue(node) go direction)
    }.find { (_, node) -> node == "ZZZ" })
}

data class PathHistory (
    val start: String,
    val endingIndices: MutableList<Int>  = mutableListOf(),
    var visited: MutableList<Pair<Int, String>> = mutableListOf(),
    var cycleLength: Int? = null,
    var cycleStartIndex: Int? = null
) {
   fun isFinalIndex(index: ULong) =
       endingIndices.contains(index.toInt()) || endingIndices.filter { it >= cycleStartIndex!! }.any { endingIndex ->
           (index  - endingIndex.toULong()) % cycleLength!!.toULong() == 0.toULong()
       }

}

fun buildPathHistory(start: String): PathHistory {
    val (directions, nodeMap) = parseInput()
    val pathHistory = PathHistory(start)
    val cycleStart = directions.repeating().runningFold(0 to start) {(index, node), direction ->
        val nextNode = nodeMap[node]!! go direction
        index + 1 to nextNode
    }.find { (index, node) ->
        val nextDirectionIndexed = index.mod(directions.size) to node
        val result = pathHistory.visited.contains(nextDirectionIndexed)
        if (!result) pathHistory.visited += nextDirectionIndexed
        if (node.last() == 'Z') pathHistory.endingIndices += index
        result
    }!!
    println(cycleStart)
    pathHistory.cycleStartIndex = pathHistory.visited
        .indexOf(cycleStart.first.mod(directions.size) to cycleStart.second)
    pathHistory.cycleLength = pathHistory.visited.size - pathHistory.cycleStartIndex!!
    return pathHistory
}

fun part2() {
    val (directions, nodeMap) = parseInput()
    val histories = nodeMap.keys.filter { it.last() == 'A' }.map(::buildPathHistory)
    histories.forEach {pathHistory ->
            println("${pathHistory.start}, ${pathHistory.cycleStartIndex}, ${pathHistory.cycleLength}, ${pathHistory.endingIndices}")
            println("${pathHistory.visited[pathHistory.endingIndices.first().toInt()]}")
        }
    var index = 1.toULong()
    val generator = histories.minOf { it.cycleLength!! }.toULong()
    val generatorSequence = generateSequence {
        generator * index++
    }
    println(generatorSequence.find { i ->
        histories.all { it.isFinalIndex(i) }
    })

}

enum class Direction {
    Left,
    Right
}

fun Char.toDirection() = when (this) {
    'L' -> Left
    'R' -> Right
    else -> throw IllegalArgumentException("$this is an invalid direction")
}

infix fun <T> Pair<T, T>.go(direction: Direction) = when (direction) {
    Left -> first
    Right -> second
}

fun parseInput(): Pair<List<Direction>, Map<String, Pair<String, String>>> {
    val input = readLines("day8/input.txt")

    val parseLine = { line: String ->
        val parts = line.split("=").map { it.trim() }
        val pair = parts.last().removeSurrounding("(", ")")
            .split(",").map { it.trim() }
        parts.first() to (pair.first() to pair.last())
    }

    return input.first().map(Char::toDirection) to input.drop(2).associate(parseLine)
}

fun <T> List<T>.repeating(): Sequence<T> {
    var index = -1
    return generateSequence {
        index = (index + 1).mod(this.size)
        this[index]
    }
}