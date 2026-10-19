# Create a DataTable column filter

Filters combine with AND in `filter_columns()`. Predicates can also be
supplied directly as `function(values) logical`.

## Usage

``` r
table_filter(
  type = c("equals", "contains", "regex", "range", "missing"),
  value = NULL,
  min = NULL,
  max = NULL,
  case_sensitive = FALSE,
  inclusive = TRUE
)
```

## Arguments

- type:

  One of `"equals"`, `"contains"`, `"regex"`, `"range"`, or `"missing"`.

- value:

  Comparison value, text pattern, or regular expression.

- min, max:

  Inclusive or exclusive range bounds.

- case_sensitive:

  Case-sensitive text matching?

- inclusive:

  Include range endpoints?

## Value

An object suitable for a named `filter_columns()` list.
