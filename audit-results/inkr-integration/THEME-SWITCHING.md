# Theme switching

Termr's `app$theme` and inkr stylesheet variables are separate. Inkr resolves
variables while compiling; it has no connection to termr theme tokens. A termr
theme change updates termr defaults and theme tokens, while explicit inkr color
declarations remain as compiled.

To switch both systems together, compile the inkr variants in advance and
replace the sheet atomically:

```r
app$theme <- "dark"
app$set_inkr_stylesheet(dark_sheet)
```

`set_inkr_stylesheet()` compiles and validates before changing the current
sheet. The cache is cleared after a successful replacement. A failed compile
leaves the previous inkr sheet active. See
`inst/examples/inkr-theme-switch.R`.
