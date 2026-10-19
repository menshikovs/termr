# Checkbox

A labelled toggle. Space, Enter or a click toggles it and sends
`"checkbox.changed"` (`event$data$value`).

## Usage

``` r
checkbox(
  label = "",
  value = FALSE,
  id = NULL,
  classes = NULL,
  style = NULL,
  disabled = FALSE
)
```

## Arguments

- label:

  Label text.

- value:

  Initial state.

- id:

  Optional identifier.

- classes:

  Optional classes.

- style:

  A [`style()`](https://menshikovs.github.io/termr/reference/style.md).

- disabled:

  Disabled checkboxes cannot be toggled.

## Value

A `Checkbox` widget with a reactive `value`.

## Examples

``` r
checkbox("Enable logs", value = TRUE, id = "logs")
#> <Checkbox #logs>
```
