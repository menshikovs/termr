# Themes

A theme gives names to colours. Use them in styles and stylesheets as
`"$name"`, e.g. `style(background = "$primary")`. Built-in widgets use
theme colours, so a theme restyles a whole app:
`app(ui, theme = "dark")` or
`app$theme <- termr_theme("light", accent = "purple")`.

## Usage

``` r
termr_theme(base = "default", ..., name = base)
```

## Arguments

- base:

  Name of a built-in theme to start from.

- ...:

  Colours to set, e.g. `primary = "#8a2be2"`.

- name:

  Name of the theme.

## Value

A `termr_theme`.

## Details

Named `termr_theme()` so that it does not mask `ggplot2::theme()`.

Colour names: `foreground`, `background` (screen background), `surface`
(headers, panels), `muted` (secondary text, guides, disabled widgets),
`primary` and `on_primary` (primary buttons, cursors), `accent` (focus),
`success`, `warning`, `error`, `information`, `stripe` (zebra rows).
Extra names can be added.

Built-in themes: `"default"` (the terminal's own 16-colour palette),
`"dark"` and `"light"` (24-bit colours) and `"high-contrast"` (black and
white with saturated yellow / cyan highlights and a heavier border
around the focused widget).

On a terminal without colour (`NO_COLOR`, `TERM=dumb`) selections and
cursors are drawn in reverse video, errors in bold underline and
secondary text dimmed, so nothing depends on colour alone.

## Examples

``` r
termr_theme("dark", accent = "orange")
#> <theme dark: foreground = #e0e0e0, background = #121212, surface = #2b2b2b, muted = #7a7a7a, primary = #0178d4, on_primary = #ffffff, accent = #ffa500, success = #4ebf71, warning = #ffa62b, error = #e05a6e, information = #59a8f0, stripe = #1c1c1c>
```
