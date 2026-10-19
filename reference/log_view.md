# Log view

A scrolling log for long-running work.
[`write()`](https://rdrr.io/r/base/write.html) appends lines with a
level (`"debug"`, `"info"`, `"success"`, `"warning"`, `"error"`, shown
in different colours). Only the last `max_lines` lines are kept, so
memory stays bounded. While the view is scrolled to the end it follows
new lines; scroll up (keys or wheel) to read older lines, or `pause()`.

## Usage

``` r
log_view(
  max_lines = 1000L,
  timestamps = FALSE,
  auto_scroll = TRUE,
  id = NULL,
  classes = NULL,
  style = NULL
)
```

## Arguments

- max_lines:

  Number of lines kept.

- timestamps:

  Prefix lines with `HH:MM:SS`?

- auto_scroll:

  Follow new lines?

- id:

  Optional identifier.

- classes:

  Optional classes.

- style:

  A [`style()`](https://menshikovs.github.io/termr/reference/style.md).

## Value

A `LogView` widget with methods
[`write()`](https://rdrr.io/r/base/write.html), `clear()`, `pause()`,
`resume()`.

## Examples

``` r
logs <- log_view(max_lines = 500, id = "log")
logs$write("Starting model...")
logs$write("Convergence is slow", level = "warning")
```
