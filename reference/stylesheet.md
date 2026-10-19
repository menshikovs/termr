# Stylesheets

Parse termr stylesheets (RTCSS, a small CSS-like language) to style many
widgets at once by type, id, class and state. Pass them to
`app(stylesheet = )` or `app$add_stylesheet()`.

## Usage

``` r
stylesheet(text, source = "<stylesheet>")

stylesheet_file(path)
```

## Arguments

- text:

  Stylesheet text.

- source:

  Name used in error messages.

- path:

  Path to a stylesheet file.

## Value

A `termr_stylesheet`.

## Details

    Button { border: round; padding: 0 2; }
    Button.danger { background: $error; }
    #save { width: 20; }
    Input:focus { border: heavy $accent; }
    Vertical > Label { bold: true; }

Properties are the arguments of
[`style()`](https://menshikovs.github.io/termr/reference/style.md)
(`border-color` and `border_color` both work). `border` also accepts a
colour: `border: round cyan`. Colours can refer to the theme:
`$primary`. Errors report the line, column and property.

Rules apply above a widget type's built-in style and below a widget's
own `style`. More specific selectors win (ids over classes and pseudo
classes over types); among equally specific rules, later ones win.

## Examples

``` r
sheet <- stylesheet("Button { border: round; } #save { background: $primary; }")
sheet
#> <stylesheet <stylesheet>: 2 rule(s)>
#>   Button <style border = "round">
#>   #save <style background = "$primary">
```
