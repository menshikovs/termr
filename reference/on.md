# Event handlers

`on()` creates an event handler that can be passed to
[`app()`](https://menshikovs.github.io/termr/reference/app.md) together
with the widgets. It is equivalent to calling `app$on()`.

## Usage

``` r
on(type, selector = NULL, handler)
```

## Arguments

- type:

  Event type such as `"button.pressed"`, `"input.submitted"`, `"key"`,
  `"resize"`, `"focus"` or `"mount"`. `"*"` matches any type.

- selector:

  Optional selector (e.g. `"#hello"`, `".danger"`, `"Button"`) matched
  against the sender (for key and mouse events: the widget the event was
  sent to).

- handler:

  `function(event, app)`.

## Value

An object of class `termr_handler`.

## Details

The handler runs when an event of the given type reaches the app and, if
a selector is given, the widget that sent the event matches it.

## Examples

``` r
on("button.pressed", "#hello", function(event, app) {
  app$query_one("#output")$update("Hello!")
})
#> $type
#> [1] "button.pressed"
#> 
#> $selector
#> [1] "#hello"
#> 
#> $handler
#> function (event, app) 
#> {
#>     app$query_one("#output")$update("Hello!")
#> }
#> <environment: 0x556cb407b330>
#> 
#> attr(,"class")
#> [1] "termr_handler"
```
