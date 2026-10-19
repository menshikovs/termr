# Register an experimental custom container layout

A registered name can be used as `layout` in
[`style()`](https://menshikovs.github.io/termr/reference/style.md).
Custom names start with `custom_` to keep built-in names reserved.

## Usage

``` r
register_layout(name, arrange, measure, replace = FALSE)
```

## Arguments

- name:

  A unique `custom_` name.

- arrange:

  `function(children, inner, parent_style)` returning one
  [`region()`](https://menshikovs.github.io/termr/reference/region.md)
  per child.

- measure:

  `function(children, parent_style)` returning `width()` and
  `height(width)` functions.

- replace:

  Replace an existing registration of `name`? Packages that register in
  `.onLoad()` can pass `TRUE` so that reloading them works. Built-in
  layouts can never be replaced (their names do not start with
  `custom_`).

## Value

The registered name, invisibly.
