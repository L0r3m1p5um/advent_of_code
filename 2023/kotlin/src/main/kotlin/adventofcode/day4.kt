package adventofcode.day4

import adventofcode.common.readLines

fun main() {
    println("Part 1")
    part1()
    println("Part 2")
    part2()
}

fun parseLine(line: String): Card {
    val input = line.drop(4).trim().split(":")
    val id = input.first().toIntOrNull()!!
    val numbers = input.last().split('|')
        .map { it.trim().split("\\s+".toRegex())
            .map { num -> num.toIntOrNull()!!}
        }
    return Card(
        id,
        numbers.first().toSet(),
        numbers.last().toSet()
    )
}

fun Int.power(n: Int) = (0 until n).fold(1) { acc, _ -> acc * this}

fun part1() {
    println(readLines("day4/input.txt")
        .map {
            val winningCount = parseLine(it).winningNumberCount()
            if (winningCount == 0) 0 else 2.power(winningCount - 1)
        }.sum())

}

fun part2() {
    val cards = readLines("day4/input.txt")
        .map(::parseLine)
    val cardCounts = cards.map(Card::id).associateWith { 1 }.toMutableMap()
    cards.forEach {card ->
        card.cardsWon().forEach {cardWonId ->
            cardCounts.merge(cardWonId, 0) { value, _->
                value + cardCounts[card.id]!!
            }
        }
    }
    println(cardCounts.values.sum())
}

data class Card(
    val id: Int,
    val winningNums: Set<Int>,
    val nums: Set<Int>
) {
    fun winningNumberCount() = (winningNums intersect nums ).count()
    fun cardsWon() = (id + 1..id + winningNumberCount())
}
