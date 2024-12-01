package adventofcode.day5

import adventofcode.common.readText

fun main() {
    part2()
}

fun part2() {
    val (seeds, ranges) = parseInput()
    val breakpoints = seeds.map(Pair<Long, Long>::first) +
            ranges.flatMapIndexed { index, next ->
                next.breakpoints().map {
                    // map breakpoints for each mapping back to seed numbers
                    ranges.reversed().drop(ranges.size - index).fold(it) { acc, mapping ->
                        acc.almanacInverse(mapping)
                    }
                }
            }.filter { breakpoint ->
                seeds.any {
                    it.first <= breakpoint && breakpoint < it.first + it.second
                }
            }
    val result = breakpoints.map { breakpoint ->
        ranges.fold(breakpoint) { acc, next ->
            acc.almanacMap(next)
        }
    }.min()
    println(result)
}

fun parseInput(): Pair<List<Pair<Long, Long>>, List<List<AlmanacMapping>>> {
    val maps = readText("day5/input.txt").split("\r\n\r\n")
    val seeds = maps.first().trim().split(' ').drop(1)
        .map { it.toLongOrNull()!! }
        .chunked(2).map { it.first() to it.last() }
    val ranges = maps.drop(1).map {
        it.split('\n').drop(1).map { line ->
            line.trim().split(' ').map { num -> num.toLongOrNull()!! }
        }.map { list ->
            AlmanacMapping(
                list[0]!!,
                list[1]!!,
                list[2]!!
            )
        }
    }
    return seeds to ranges
}

fun Long.almanacMap(map: List<AlmanacMapping>): Long {
    val mapping = map.find { it.sourceStart <= this && this < it.sourceStart + it.length }
    return if (mapping == null) {
        this
    } else {
        mapping.destStart + (this - mapping.sourceStart)
    }
}

fun Long.almanacInverse(map: List<AlmanacMapping>): Long {
    val mapping = map.find { it.destStart <= this && this < it.destStart + it.length }
    return if (mapping == null) {
        this
    } else {
        mapping.sourceStart + (this - mapping.destStart)
    }
}

data class AlmanacMapping(
    val destStart: Long,
    val sourceStart: Long,
    val length: Long
)

fun List<AlmanacMapping>.breakpoints() =
    flatMap { map -> listOf(map.sourceStart, map.sourceStart + map.length - 1) }