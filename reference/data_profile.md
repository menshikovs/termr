# Compact vector profile

Summarizes numeric/integer, character/factor, logical, Date, and POSIXct
vectors. Numeric summaries use base R type-7 quartiles and sample
standard deviation ([`stats::sd`](https://rdrr.io/r/stats/sd.html)).
Numeric data also gets an eight-bin histogram rendered with the existing
sparkline widget. Without `sample`, vector summaries analyze the full
in-memory vector. Character top-value counts cap their frequency table
at 100,000 analyzed non-missing values. Supplying `sample` analyzes
deterministic, evenly spaced positions. A `table_source` is rejected to
prevent an implicit full scan; fetch or sample data explicitly first.
`data` may also be a reactive function.

## Usage

``` r
data_profile(
  data,
  name = NULL,
  sample = NULL,
  top_n = 5L,
  id = NULL,
  classes = NULL,
  style = NULL,
  disabled = FALSE
)
```

## Arguments

- data:

  An atomic vector, factor, Date, or POSIXct vector.

- name:

  Heading for the profile.

- sample:

  Optional positive number of evenly spaced values to analyze.

- top_n:

  Number of frequent character/factor values to display.

- id:

  Optional identifier.

- classes:

  Optional classes.

- style:

  A [`style()`](https://menshikovs.github.io/termr/reference/style.md).

- disabled:

  Disable the widget?

## Value

A `DataProfile` widget with reactive `$data` and `$summary`.

## Examples

``` r
data_profile(mtcars$mpg, name = "mpg")
#> <DataProfile>
#> ├── <Label> "mpg"
#> ├── <KeyValue>
#> ├── <Label> "Distribution"
#> └── <Sparkline>
```
