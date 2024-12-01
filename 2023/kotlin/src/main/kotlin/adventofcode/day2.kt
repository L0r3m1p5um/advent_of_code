package adventofcode

import adventofcode.common.readText


fun main() {
    val input = readText("day2/input.txt")
    part2(input)
}

fun part1(input: String) {
    val bag = mapOf(
        Color.Red to 12,
        Color.Green to 13,
        Color.Blue to 14
    )

    val gameIsValid = { game: List<Map<Color, Int>> ->
         !game.any {
            Color.values().any { color ->
                it.getOrDefault(color, 0) > bag[color]!!
            }
         }
    }
    val games= parseInput(input)
    println(games.filter {
        gameIsValid(it.value)
    }.keys.sum())
}

fun part2(input: String) {
    val games = parseInput(input).values
    println(games.map { game ->
        Color.values().associateWith { color->
            game.maxOf { it.getOrDefault(color, 0) }
        }
    }.map { it.values.fold(1) { acc,it -> acc * it} }
        .sum())
}

fun parseInput(input: String): Map<Int, List<Map<Color, Int>>> {
    val parseLine = { s: String ->
        val (id, remaining) = s.gameId()
        id to remaining.parseRounds()
    }
    return input.lines().associate(parseLine)
}

fun String.gameId(): Pair<Int, String> {
    var remaining = removePrefix("Game ")
    val id = remaining.substringBefore(':')
    return id.toIntOrNull()!! to remaining.drop(id.length + 2)
}

fun String.parseRounds(): List<Map<Color, Int>> =
    split(';').map {
        it.split(',').map(String::trim)
            .associate { colorValue ->
                val words = colorValue.split(' ')
                when (words[1]) {
                    "blue" -> Color.Blue
                    "red" -> Color.Red
                    "green" -> Color.Green
                    else -> throw IllegalArgumentException("Invalid color name: ${words[1]}")
                } to words.first().toIntOrNull()!!
            }
    }

enum class Color {
    Red, Green, Blue
}