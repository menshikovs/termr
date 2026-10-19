# Drop-down select

Shows the selected choice; Enter, Space, Down or a click opens a list
below it. Choosing an option sends `"dropdown.changed"` (`event$data`:
`value`, `label`); Escape or a click outside closes the list.

## Usage

``` r
dropdown(
  choices,
  value = NULL,
  prompt = "Select",
  id = NULL,
  classes = NULL,
  style = NULL,
  disabled = FALSE
)
```

## Arguments

- choices:

  A character vector; names, if present, are shown.

- value:

  Initially selected value, or `NULL`.

- prompt:

  Text shown when nothing is selected.

- id:

  Optional identifier.

- classes:

  Optional classes.

- style:

  A [`style()`](https://menshikovs.github.io/termr/reference/style.md).

- disabled:

  Disabled selects cannot be opened.

## Value

A `Select` widget with a reactive `value`.

## Details

Named `dropdown()` rather than `select()` so that it does not mask
`dplyr::select()`; the widget type (for selectors) is `Select`.

## Examples

``` r
dropdown(c("Comma separated" = "csv", "JSON" = "json"), value = "csv", id = "format")
#> <Select #format>
```
