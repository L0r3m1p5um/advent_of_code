package adventofcode.day7

import adventofcode.common.readLines
import adventofcode.day7.Card.*
import adventofcode.day7.HandType.*

fun main() {
    println("Part 1")
    part1()
    println("Part 2")
    part2()
}

fun part1() = println(parseInput().sorted().mapIndexed { index, hand ->
    (index + 1) * hand.bid
}.sum())

fun part2() = println(parseInputPart2().sorted().mapIndexed { index, hand ->
    (index + 1) * hand.bid
}.sum())


fun parseInput() =
    readLines("day7/input.txt").map { line ->
        val words = line.split(" ")
        Hand(
            words.first().map(Char::toCard),
            words.last().toIntOrNull()!!
        )
    }

fun parseInputPart2() = parseInput().map {(cards, bid) -> HandPart2(cards, bid)}

data class Hand(val cards: List<Card>, val bid: Int) : Comparable<Hand> {
    val type: HandType
        get() {
            val counts = Card.values().map { card ->
                cards.count { card == it }
            }.filter { it != 0 }.sorted()
            return when (counts) {
                listOf(5) -> FiveOfAKind
                listOf(1, 4) -> FourOfAKind
                listOf(2, 3) -> FullHouse
                listOf(1, 1, 3) -> ThreeOfAKind
                listOf(1, 2, 2) -> TwoPair
                listOf(1, 1, 1, 2) -> OnePair
                else -> HighCard
            }
        }


    override fun compareTo(other: Hand) =
        when (type.compareTo(other.type)) {
            0 -> cards.zip(other.cards).fold(0) { acc, (thisCard, otherCard) ->
                when (acc) {
                    0 -> thisCard.compareTo(otherCard)
                    else -> acc
                }
            }
            else -> type.compareTo(other.type)
        }
}

data class HandPart2(val cards: List<Card>, val bid: Int) : Comparable<HandPart2> {
    val type: HandType
        get() {
            val counts= Card.values().map { card ->
                card to cards.count { card == it }
            }.filter { it.second != 0 }.toMap().toMutableMap()
            if (counts.containsKey(Jack)) {
                val jokers = counts.getValue(Jack)
                counts.remove(Jack)
                val jokerValue = counts.filter {(_, value) ->
                    value == counts.maxOf { it.value }
                }.map { it.key }.maxOrNull() ?: Jack
                counts[jokerValue] = (counts[jokerValue] ?: 0) + jokers
            }
            return when (counts.values.toList().sorted()) {
                listOf(5) -> FiveOfAKind
                listOf(1, 4) -> FourOfAKind
                listOf(2, 3) -> FullHouse
                listOf(1, 1, 3) -> ThreeOfAKind
                listOf(1, 2, 2) -> TwoPair
                listOf(1, 1, 1, 2) -> OnePair
                else -> HighCard
            }
        }


    override fun compareTo(other: HandPart2) =
        when (type.compareTo(other.type)) {
            0 -> cards.zip(other.cards).fold(0) { acc, (thisCard, otherCard) ->
                when (acc) {
                    0 -> thisCard.comparePart2(otherCard)
                    else -> acc
                }
            }

            else -> type.compareTo(other.type)
        }
}


fun Char.toCard() = when (this) {
    '2' -> Two
    '3' -> Three
    '4' -> Four
    '5' -> Five
    '6' -> Six
    '7' -> Seven
    '8' -> Eight
    '9' -> Nine
    'T' -> Ten
    'J' -> Jack
    'Q' -> Queen
    'K' -> King
    'A' -> Ace
    else -> throw IllegalArgumentException("'$this' is not a valid card value")
}

enum class HandType {
    HighCard,
    OnePair,
    TwoPair,
    ThreeOfAKind,
    FullHouse,
    FourOfAKind,
    FiveOfAKind
}

enum class Card {
    Two,
    Three,
    Four,
    Five,
    Six,
    Seven,
    Eight,
    Nine,
    Ten,
    Jack,
    Queen,
    King,
    Ace;

    fun comparePart2(other: Card) = when (this to other) {
        this to this -> 0
        Jack to other -> -1
        this to Jack -> 1
        else -> this.compareTo(other)
    }
}