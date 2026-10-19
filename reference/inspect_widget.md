# Inspect a widget

Collects what termr knows about a widget: type, id, classes, region,
states, reactive state values, computed style, matching stylesheet
rules, bindings, parent and children. Printing the result gives a
readable report.

## Usage

``` r
inspect_widget(x, selector = NULL)
```

## Arguments

- x:

  An [App](https://menshikovs.github.io/termr/reference/App-class.md) or
  a widget.

- selector:

  A selector to find the widget when `x` is an app (or a container).

## Value

A list of class `termr_inspection`.

## Examples

``` r
ui <- vertical(button("Save", id = "save", classes = "primary"))
inspect_widget(ui, "#save")
#> <Button #save>
#> classes:    primary
#> types:      Button < Widget
#> region:     -
#> visible:    TRUE (displayed: TRUE), enabled: TRUE, focusable: TRUE
#> states:     -
#> parent:     <Vertical>
#> children:   -
#> state:
#>   disabled     FALSE
#>   label        Save
#>   pressed      FALSE
#>   visible      TRUE
#> style:
#>   width        auto
#>   height       auto
#>   margin       0 0 0 0
#>   padding      0 1 0 1
#>   border       round
#>   layout       vertical
#>   align        center
#>   valign       top
#>   wrap         none
#>   foreground   
#>   background   -
#>   border_color 
#> bindings:    <binding enter,space -> press> 
```
