# Process view

Runs an external program (without a shell) and shows its output in a
scrolling log: standard output as normal lines and standard error in the
error colour, under a one-line status. The process starts when the view
is mounted (or call `$start()`), is cancelled when the view is removed
or the app exits, and sends `"process.finished"` (`status`, `state`)
when it ends. Ctrl+X cancels it and Ctrl+R restarts it while the view
has focus. **Experimental.**

## Usage

``` r
process_view(
  command,
  args = character(),
  wd = NULL,
  env = NULL,
  timeout = NULL,
  autostart = TRUE,
  max_lines = 2000L,
  id = NULL,
  classes = NULL,
  style = NULL
)
```

## Arguments

- command:

  The program (a path or a name on the `PATH`).

- args:

  Arguments, one element each; never interpreted by a shell.

- wd:

  Working directory (`NULL`: current).

- env:

  Named character vector of extra environment variables.

- timeout:

  Seconds before the process is stopped (`NULL`: no limit).

- autostart:

  Start when mounted?

- max_lines:

  Output lines kept.

- id, classes, style:

  Common widget arguments.

## Value

A `ProcessView` widget with `$start()`, `$cancel()`, `$restart()`,
`$running`, `$output` and `$worker`.

## Examples

``` r
pv <- process_view(file.path(R.home("bin"), "Rscript"), c("-e", "cat('hi\\n')"),
                   autostart = FALSE)
pv$running
#> [1] FALSE
```
