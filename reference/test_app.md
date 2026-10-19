# Test an app without a terminal

Starts the app with a headless driver and returns a `Pilot` that
simulates the user. Every action runs one tick of the real event loop
(input -\> events -\> timers -\> repaint), and the output goes through
the real renderer into a virtual terminal, so tests see exactly what a
user would see.

## Usage

``` r
test_app(app, width = 80L, height = 24L, color_mode = "truecolor")
```

## Arguments

- app:

  An [App](https://menshikovs.github.io/termr/reference/App-class.md) or
  a widget.

- width, height:

  Virtual terminal size.

- color_mode:

  Colour support of the virtual terminal: `"truecolor"` (default),
  `"256"`, `"16"` or `"none"` (monochrome, as with `NO_COLOR`).

## Value

A `Pilot` object.

## Details

Pilot methods:

- `press(...)`: press keys, e.g. `press("tab", "enter", "ctrl+c")`;

- `type(text)`: type characters;

- `resize(width, height)`: resize the terminal;

- `advance(seconds)`: let simulated time pass (fires timers);

- `click(target, y = NULL, button = "left")`: click a widget (a selector
  or widget; the centre of its visible part is used) or a position
  `click(x, y)`;

- `hover(target)`, `scroll(target, direction = "down", times = 1)`: move
  the pointer, turn the mouse wheel;

- `mouse(action, x, y, button, direction)`: send a raw mouse event;

- `drag(from, to, button = "left", steps = 3)`: press, move and release
  between two positions (selectors, widgets or `c(x, y)`);

- `paste(text)`: deliver a bracketed paste; `system_clipboard()`: text
  of the last OSC 52 write;

- `focus(target)`, `find(selector)`: focus a widget, find one;

- `wait_for(condition, timeout = 5)`: step the event loop (simulated
  time, real time while workers run) until `condition(app)` is `TRUE`;

- `run_worker(fn, ..., wait = TRUE)`: start a worker and wait for it;

- `wait_for_workers(timeout)`: wait for background workers to finish;

- `screen_text()`: the visible screen as a character vector;

- `snapshot()`: print the screen (for
  [`testthat::expect_snapshot()`](https://testthat.r-lib.org/reference/expect_snapshot.html));

- `query_one(selector)`, `query(selector)`: find widgets;

- [`stop()`](https://rdrr.io/r/base/stop.html): exit the app and restore
  the (virtual) terminal.

Fields: `app`, `driver`, `exited` and `value` (the value passed to
`app$exit()`).

## Examples

``` r
pilot <- test_app(app(input(id = "name")), width = 30, height = 5)
pilot$type("Ada")
pilot$query_one("#name")$value
#> [1] "Ada"
pilot$stop()
```
