# Option list

A scrollable list of choices. Up/Down/Page Up/Page Down/Home/End move
the highlight (sending `"option_list.highlighted"`); Enter or a click
selects (`"option_list.selected"`). `event$data` has `index`, `value`
and `label`.

## Usage

``` r
option_list(choices, id = NULL, classes = NULL, style = NULL)
```

## Arguments

- choices:

  A character vector. Names, if present, are shown instead of the
  values.

- id:

  Optional identifier.

- classes:

  Optional classes.

- style:

  A [`style()`](https://menshikovs.github.io/termr/reference/style.md).

## Value

An `OptionList` widget with field `value`.

## Examples

``` r
option_list(c(Comma = "csv", JSON = "json", Parquet = "parquet"))
#> <OptionList>
```
