# Column options for data tables

Column options for data tables

## Usage

``` r
column(
  label = NULL,
  width = NULL,
  align = NULL,
  formatter = NULL,
  min_width = NULL,
  max_width = NULL,
  visible = TRUE,
  sortable = TRUE,
  editable = NULL
)
```

## Arguments

- label:

  Header text (defaults to the column name).

- width:

  Fixed width in cells; `NULL` estimates it from the data.

- align:

  `"left"`, `"right"` or `"center"`; numbers default to right.

- formatter:

  `function(x)` turning a vector of values into strings.

- min_width, max_width:

  Limits for the estimated width.

- visible:

  Show the column? (Hidden columns stay in the data; see
  `set_column_visible()`.)

- sortable:

  Can the table be sorted by this column?

- editable:

  Can cells be edited (when the table is `editable`)? `NULL`: yes for
  numeric, logical, character, factor and date columns.

## Value

An object of class `termr_column`.

## Examples

``` r
column(label = "Score", width = 8, align = "right",
       formatter = function(x) sprintf("%.1f", x))
#> $label
#> [1] "Score"
#> 
#> $width
#> [1] 8
#> 
#> $align
#> [1] "right"
#> 
#> $formatter
#> function (x) 
#> sprintf("%.1f", x)
#> <environment: 0x5602dd00a960>
#> 
#> $min_width
#> NULL
#> 
#> $max_width
#> NULL
#> 
#> $visible
#> [1] TRUE
#> 
#> $sortable
#> [1] TRUE
#> 
#> $editable
#> NULL
#> 
#> attr(,"class")
#> [1] "termr_column"
```
