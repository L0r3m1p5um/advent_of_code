package adventofcode.day1

import adventofcode.common.readLines

fun main() {
    part2()
}

fun part1() {
    val processLine = { line: String ->
        val digits = line.filter { it in '0'..'9'}
        10 * digits.first().digitToInt() +  digits.last().digitToInt()
    }

    println(readLines("day1/input.txt")
        .map(processLine).sum())
}

fun part2() {
    val tokens =
        (0..9).map {"$it"} +
        listOf(
        "one",
        "two",
        "three",
        "four",
        "five",
        "six",
        "seven",
        "eight",
        "nine"
    )

    fun String?.tokenValue() : Int? = when (this) {
        "0" -> 0
        "1", "one" -> 1
        "2", "two" -> 2
        "3", "three" -> 3
        "4", "four" -> 4
        "5", "five" -> 5
        "6", "six" -> 6
        "7", "seven" -> 7
        "8", "eight" -> 8
        "9", "nine" -> 9
        else -> null
    }

    val parseTokens ={x: String ->
        generateSequence(Pair<Int?, String>(null, x)) { (last, remaining) ->
            // If there's no remaining input, end the sequence
            if (remaining.isEmpty()) null
            else {
                val nextToken = tokens.find { remaining.startsWith(it) }
                nextToken.tokenValue() to remaining.drop(1)
            }
    }}

    val getCalibrationValue = { line: String ->
        val digits = parseTokens(line).mapNotNull { it.first }
        10 * digits.first() +  digits.last()
    }

    println(readLines("day1/input.txt")
        .map(getCalibrationValue).sum())
}