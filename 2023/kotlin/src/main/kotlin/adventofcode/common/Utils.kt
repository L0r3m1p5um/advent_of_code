package adventofcode.common

import java.io.File
import kotlin.io.path.Path

fun readLines(filename: String) = File(Path("src/main/resources", filename).toUri()).readLines()
fun readText(filename: String) = File(Path("src/main/resources", filename).toUri()).readText()

fun <T, R> List<T>.combinations(list: List<R>) = fold(listOf<Pair<T,R>>()) {
    acc, next ->
    acc + list.map { next to it}
}

fun <T> List<T>.combinations() = combinations(this)

fun<T> List<List<T>>.withCoordinates(): List<List<Pair<Pair<Int,Int>, T>>> =
    mapIndexed { rowIndex , row ->
        row.mapIndexed { colIndex, it ->
            (rowIndex to colIndex) to it
        }
    }

fun<T> List<List<T>>.adjacent(row: Int, col: Int) =
    listOf(0,1,-1).combinations().map {
            (x, y) -> row + x to col + y
    }.filter { it != 0 to 0}.mapNotNull { (x, y) ->
        this.getOrNull(x)?.getOrNull(y)
    }
