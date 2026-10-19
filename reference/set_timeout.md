# Timers

Run a function later (`set_timeout()`) or repeatedly (`set_interval()`).
Timers are part of the event loop: callbacks run between events, never
concurrently, and never block the interface. Widgets have their own
`widget$set_timeout()` / `widget$set_interval()`, whose timers are
cancelled when the widget is removed.

## Usage

``` r
set_timeout(delay, callback, app = current_app())

set_interval(interval, callback, app = current_app())
```

## Arguments

- delay, interval:

  Seconds.

- callback:

  `function(app)`.

- app:

  The app; defaults to the running app.

## Value

A [Timer](https://menshikovs.github.io/termr/reference/Timer.md); call
`$cancel()` to stop it.

## Examples

``` r
clock <- app(label("", id = "clock"), bind("q", "quit"))
clock$set_interval(1, function(app) {
  app$query_one("#clock")$update(format(Sys.time(), "%H:%M:%S"))
})
#> <Timer interval 1s, runs: 0>
if (interactive()) run(clock)
```
