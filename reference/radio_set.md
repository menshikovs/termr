# Radio buttons

`radio_set()` groups `radio_button()`s so that one can be selected.
Space, Enter or a click selects an option; Up/Down move between options.
Changes send `"radio_set.changed"` (`event$data`: `value`, `index`,
`label`) from the set.

## Usage

``` r
radio_set(..., selected = NULL, id = NULL, classes = NULL, style = NULL)

radio_button(label, value = label, id = NULL, disabled = FALSE)
```

## Arguments

- ...:

  `radio_button()`s.

- selected:

  Value selected initially.

- id:

  Optional identifier.

- classes:

  Optional classes.

- style:

  A [`style()`](https://menshikovs.github.io/termr/reference/style.md).

- label:

  Label of the option.

- value:

  Value of the option (defaults to the label).

- disabled:

  Can the option be selected?

## Value

A `RadioSet` widget with a `value` field.

## Examples

``` r
radio_set(radio_button("CSV", "csv"), radio_button("JSON", "json"), selected = "csv")
#> <RadioSet>
#> ├── <RadioButton>
#> └── <RadioButton>
```
