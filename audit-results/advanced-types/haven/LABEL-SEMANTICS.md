# Labelled and missing-value semantics

## Raw values and value labels

The stored vector remains the data source of truth. A value label is a named
mapping from a label string to one raw value. Raw mode displays that value;
label mode displays both the label and raw value. Neither mode calls
`as_factor()` or changes the input vector.

For edits:

| Input | Meaning |
| --- | --- |
| `1` | Raw numeric value 1, unless it collides with a different label mapping |
| `Male` | Exact, unambiguous value label `Male` |
| `raw:1` | Raw numeric/integer value 1, even if a label collides |
| `raw:M` | Raw character value `M` |
| `label:1` | Label named `1`, when that mapping is unique |
| `NA` | Ordinary typed missing value |
| `NaN` | Double NaN, distinct from ordinary NA |
| `NA(a)` … `NA(z)` | Haven tagged NA with the requested tag |

Duplicate label names that map to different raw values are ambiguous and
rejected. Unknown character values are rejected unless written with `raw:`.
Unknown numeric raw values are accepted as explicit numeric values. No input
is evaluated as R code.

## Tagged missing values

With `haven` available, tagged NA values are identified with
`haven::is_tagged_na()` and `haven::na_tag()`. Formatting preserves their
letter tag. Editing a tagged token calls `haven::tagged_na()` and retains the
source class and attributes. Ordinary `NA` and `NaN` are handled separately.
Sorting and assignment operate on the original labelled vector; they do not
replace tagged values with ordinary NA.

## SPSS user missings

`haven_labelled_spss` stores user-missing definitions in `na_values` and
`na_range`. DataTable exposes those exact definitions in `column_info()` and
preserves them on every edit. A raw value inside those definitions remains
the raw stored value while Haven's `is.na()` semantics continue to classify it
as a user-missing value. Termr does not turn such values into system NA and
does not change the missing definitions.

## Preserved invariants

Successful cell edits retain storage type, class, labels, variable label,
SPSS missing definitions, format attributes such as `format.spss`, display
attributes, all other source values and the distinction between tagged NA,
ordinary NA and NaN. Failed edits leave the DataTable data unchanged.
