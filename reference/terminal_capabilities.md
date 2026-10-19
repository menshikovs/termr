# Terminal capabilities

What the terminal can do, detected once by the driver and consulted by
everything above it. Detection is conservative: a feature that cannot be
recognised from `TERM`, `COLORTERM`, `NO_COLOR`, `CI` or a few
terminal-specific variables is reported as unavailable and termr falls
back (e.g. to its internal clipboard instead of OSC 52).

## Usage

``` r
terminal_capabilities(
  env = Sys.getenv(),
  windows = .Platform$OS.type == "windows",
  overrides = list()
)
```

## Arguments

- env:

  Environment variables (named character vector or list); defaults to
  the current ones.

- windows:

  Is this a Windows console?

- overrides:

  Named list of capabilities that replace detected ones.

## Value

An object of class `termr_capabilities`.

## Details

Fields of the returned list:

- `colors`: `"truecolor"`, `"256"`, `"16"` or `"none"`;

- `truecolor`, `unicode`, `mouse`, `sgr_mouse`, `bracketed_paste`,
  `alternate_screen`, `synchronized_output`, `cursor_shape`,
  `hyperlinks` (OSC 8), `osc52` (clipboard write): logical.

Overrides (all optional): `options(termr.color_mode = )`,
`options(termr.ascii = TRUE)`, `options(termr.osc52 = TRUE/FALSE)`,
`options(termr.hyperlinks = TRUE/FALSE)`, or the environment variables
`TERMR_OSC52` and `TERMR_HYPERLINKS` set to `1` / `0`.

## Examples

``` r
terminal_capabilities(env = c(TERM = "xterm-256color"), windows = FALSE)
#> <termr_capabilities>
#>   colors               256
#>   truecolor            FALSE
#>   unicode              TRUE
#>   mouse                TRUE
#>   sgr_mouse            TRUE
#>   bracketed_paste      TRUE
#>   alternate_screen     TRUE
#>   synchronized_output  FALSE
#>   cursor_shape         FALSE
#>   hyperlinks           FALSE
#>   osc52                FALSE
terminal_capabilities(env = c(TERM = "dumb"), windows = FALSE)$mouse
#> [1] FALSE
```
