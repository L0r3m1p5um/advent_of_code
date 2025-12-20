import gleam/list

pub fn fold_coords(
  grid: List(List(a)),
  acc: b,
  callback: fn(b, a, #(Int, Int)) -> b,
) {
  grid
  |> list.index_fold(acc, fn(acc, row, row_idx) {
    row
    |> list.index_fold(acc, fn(acc, it, col_idx) {
      callback(acc, it, #(row_idx, col_idx))
    })
  })
}
