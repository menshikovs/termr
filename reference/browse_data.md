# Browse a data frame in the terminal

`browse_data()` opens an interactive viewer for a data frame: summary
metrics, a virtualised table (fast for millions of rows), information
about the selected column, search across all columns, sorting, and row
details. `data_browser()` builds the same app without running it, e.g.
to customise or test it.

## Usage

``` r
browse_data(data, title = deparse(substitute(data)), ...)

data_browser(data, title = deparse(substitute(data)), ...)
```

## Arguments

- data:

  A data frame or matrix.

- title:

  Title shown at the top (defaults to the expression).

- ...:

  Passed to
  [`data_table()`](https://menshikovs.github.io/termr/reference/data_table.md)
  (e.g. `formatters`, `columns`).

## Value

`browse_data()` returns `NULL` invisibly; `data_browser()` returns an
[App](https://menshikovs.github.io/termr/reference/App-class.md).

## Details

Keys: arrows / Page Up / Page Down move the cell cursor; `/` focuses the
search box (Enter applies it, Escape in the box clears it); `s` sorts by
the current column (again: descending); `r` resets sorting and search;
Enter shows the row; `q` quits.

## Examples

``` r
viewer <- data_browser(mtcars)
pilot <- test_app(viewer, 100, 30)
pilot$press("s")
pilot$stop()
if (interactive()) browse_data(mtcars)
```
