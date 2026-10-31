# A2.2 Implementation

## Scope

`haven` is an optional Suggests dependency. The typed DataTable adapter now
recognizes `haven_labelled` and the more specific `haven_labelled_spss`
class. It accepts atomic integer, double and character storage with valid
Haven metadata. Objects with invalid metadata and labelled objects inspected
without `haven` remain viewable where base formatting permits and are
read-only.

The adapter reads `labels`, `label`, `na_values` and `na_range` directly. It
does not call `haven::as_factor()` and does not replace or convert the source
column to display labels. Normal viewport formatting processes only the
requested slice. The compact type header reports storage and labelled status;
it does not include potentially long labels.

## Display and metadata

`column(label_mode = "raw")` is the default. It shows stored values.
`column(label_mode = "labels")` shows an exact known label followed by its
stored value in brackets, for example `Male [1]`. Unlabelled values remain
raw. Tagged missing labels are shown as `Refused [NA(a)]`. SPSS user-missing
values retain their stored representation and receive an `(SPSS missing)`
marker.

`column_info()` adds `base_type`, `label_mode`, `variable_label`,
`value_labels`, `na_values`, `na_range` and `missing_definitions`. Label
definitions and missing definitions are list-columns, so they are not
flattened or truncated. Existing `prototype` and `attributes` fields expose
the exact metadata used by safe assignment.

## Edits

Text edits are parsed without evaluating user input. Known, unique labels may
be entered directly. `raw:<value>` always selects an underlying value;
`label:<label>` explicitly selects a label when a numeric token collides with
a different raw value. Bare character values are not accepted as raw input;
use `raw:<text>`. Ordinary `NA`, `NaN` and tagged values `NA(a)` through
`NA(z)` have distinct tokens.

All edits produce a scalar with the original storage type, class and complete
attribute set. Haven attributes are copied from a validated zero-length
prototype; the result is then checked again after vctrs assignment. The cell
is unchanged if parsing, casting, assignment or invariant validation fails.
No edit adds value labels or changes variable labels or SPSS missing rules.

## Files

Implementation is in `R/datatable-typed.R` and `R/widget-datatable.R`.
Regression tests are in `tests/testthat/test-datatable-haven.R` and
`tests/testthat/test-datatable-haven-optional.R`. User-facing behavior is
documented in `docs/data.md`, `man/column.Rd` and `man/DataTable-class.Rd`.
