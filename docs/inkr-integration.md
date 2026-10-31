# inkr stylesheet integration

`inkr` is an optional, standalone stylesheet parser and cascade engine. Install
it separately to use `app(..., inkr_stylesheet = ...)`. The termr app accepts
stylesheet source text, a local file path, an `ink_stylesheet_ast`, or a public
`ink_compiled_stylesheet`. Remote URLs are rejected. A replacement is parsed,
compiled before the app swaps it in, so a bad sheet leaves the current one
active.

```r
sheet <- inkr::ink_compile(inkr::ink_parse("
  .danger { color: white; background: red; text-style: bold; }
  .danger > Button { border: round yellow; padding: 0 1; }
"))
ui <- app(
  vertical(button("Delete", classes = "danger")),
  inkr_stylesheet = sheet
)
```

The cascade order is termr widget defaults, termr RTCSS stylesheets, the inkr
stylesheet, the widget's inline style, then its inline state styles. Inkr's
registry initial values are ignored unless a rule explicitly declares a
property (including `initial` or `inherit`). Inherited `color` and `text-style`
are applied only when a rule in the ancestor path supplies them. This prevents
inkr's generic registry defaults from replacing termr themes and widget
defaults.

After these layers resolve, termr's existing strong-focus and monochrome theme
handling may still enforce a heavy focus border, as it does for other style
sources.

The adapter maps `color`, `background`, `text-style`, `padding`, `margin`,
`border`, `width` and `height` to existing termr style properties. Colors pass
through termr's own normalization and terminal capability downgrade. A
transparent inkr background clears the lower style layer and leaves the
underlying screen surface unpainted. Alpha colors are rejected because termr's
framebuffer has no alpha channel.

For a cache miss, termr constructs the public `ink_element()` path and calls
`ink_compute()`. Parent elements and path prefixes are reused within the
existing widget style epoch and released on unmount or stylesheet changes.
Each app has a bounded cache keyed by selector path (type, id,
classes and pseudo states). A focus change therefore reuses unchanged paths'
mapped styles even though termr recomputes their outer styles. Reparenting or an
ancestor state/class change changes the path key; stylesheet replacement and
widget unmount reset the bounded cache. Inkr variables are compile-time values,
so selecting an inkr theme means replacing the compiled sheet with
`app$set_inkr_stylesheet()`; `app$theme` remains the separate termr theme.

`app$explain_inkr_style(widget, property)` returns inkr's public
`ink_explain()` result for the live widget path. It reports the winning rule,
overridden candidates and computed provenance without adding a renderer or
debug overlay of its own.

The bridge uses only exported inkr functions: `ink_parse()`, `ink_read()`,
`ink_compile()`, `ink_element()`, `ink_compute()` and `ink_explain()`. The
public session API was evaluated but is not used: in inkr 0.1.0, adding many
siblings to a session copies the parent's child-key vector on each insertion,
which caused quadratic allocation for wide widget trees. Inkr remains
independent of termr; termr adds no parser, cascade engine or native code.
Without the optional package and without an inkr stylesheet, the original
termr style path is unchanged.

Run the bundled examples with `run_example("inkr-stylesheet")`,
`run_example("inkr-dashboard")`, `run_example("inkr-focus")`,
`run_example("inkr-theme-switch")`, `run_example("inkr-native-chart")`,
`run_example("inkr-datatable")` and `run_example("no-inkr-stylesheet")`.
