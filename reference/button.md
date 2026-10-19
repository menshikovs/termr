# Button

A focusable button. Pressing Enter or Space while it has focus sends a
`"button.pressed"` message, which you can handle with
`on("button.pressed", "#id", function(event, app) ...)`.

## Usage

``` r
button(
  label = "Button",
  id = NULL,
  classes = NULL,
  style = NULL,
  disabled = FALSE,
  variant = "default",
  on_press = NULL
)
```

## Arguments

- label:

  Button text.

- id:

  Optional identifier (for `#id` selectors).

- classes:

  Optional classes (for `.class` selectors).

- style:

  A [`style()`](https://menshikovs.github.io/termr/reference/style.md).
  State styles `focus`, `disabled` and `states = list(pressed = ...)`
  are supported.

- disabled:

  Disabled buttons cannot be focused or pressed.

- variant:

  Colour variant: `"default"`, `"primary"`, `"success"`, `"warning"` or
  `"error"`.

- on_press:

  Optional `function()` (or `function(event, app)`) called when the
  button is pressed.

## Value

A `Button` widget.

## Examples

``` r
button("Run", id = "run", variant = "primary")
#> <Button #run> "Run"
```
