# Units type semantics

## Rendering and metadata

- `column_info()$type` combines the pillar type abbreviation with the original
  unit, for example `dbl [m]`, `dbl [km/h]` or `dbl [°C]`.
- `show_types = TRUE` displays that summary below the column header. Normal
  terminal width and Unicode cell-width handling apply; the detailed label is
  still available from `column_info()` when a narrow column clips it.
- Cell formatting drops units only from the selected visible slice. Values are
  rendered without a repeated unit suffix; the header carries the unit.
- Missing and special doubles render as `NA`, `NaN`, `Inf` and `-Inf`.

## Editing rules

| Input in an `m` column | Result |
| --- | --- |
| `12.5` | `12.5 m` |
| `125 cm` | converted to `1.25 m` |
| `2 kg` | rejected as incompatible |
| `NA` | typed missing value in `m` |
| unknown unit or malformed number | rejected with an explanatory error |

A bare number is interpreted in the column's unit. An explicit unit is parsed
and converted by the `units` package. The stored unit never changes as a result
of an edit. Affine temperature conversions, such as Fahrenheit to Celsius, use
the package's standard conversion path, including offsets.

Input accepts a single decimal/scientific number and an optional whitespace-
separated UDUNITS expression. The decimal separator is `.`. Unit names and
custom units registered through `units::install_unit()` are resolved by the
same package parser; termr does not maintain a second registry.

## Preservation and failure behavior

`table_assign_cell()` casts the scalar to the zero-length column prototype,
assigns it, then checks that storage type, class and the complete attribute
list still match. vctrs is used when available. The fallback path applies the
same class/attribute invariant. Values in other columns and rows are untouched
by conversion; failed edits leave the table data unchanged.

Unit conversion warnings are treated as unsafe edits. A finite value that
overflows to infinity, underflows away, or cannot round-trip to its input unit
within `32 * .Machine$double.eps * max(abs(input), abs(round_trip))` is rejected.
Normal floating-point rounding is therefore tolerated, while material loss of
the entered value is not silently accepted.

If the optional `units` package is unavailable, termr still loads and ordinary
DataTables continue to work. A units-class column is then read-only because
termr cannot safely parse or convert its measurements without that package.
