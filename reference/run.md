# Run an application

Takes over the terminal (alternate screen, raw keyboard input), runs the
event loop until the app calls `exit()`, and restores the terminal -
also when an error occurs or the user interrupts R.

## Usage

``` r
run(x, ...)
```

## Arguments

- x:

  An [App](https://menshikovs.github.io/termr/reference/App-class.md)
  created by
  [`app()`](https://menshikovs.github.io/termr/reference/app.md), or a
  widget (wrapped in an app).

- ...:

  Passed to `App$run()`, e.g. `driver`.

## Value

The value passed to `app$exit()`, invisibly.

## Details

When the app stops, its timers, widget timers, workers and animations
are cancelled. The same app can be run again, but timers and workers
have to be started again (for example from a `"mount"` handler).

termr apps need a real terminal: run them with `Rscript` (or an
interactive R session) in a terminal such as Windows Terminal, iTerm2 or
GNOME Terminal. RStudio's console is not a terminal.
