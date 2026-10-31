# A2.1 — Measurement-aware DataTable

## Summary

Added an internal `units` adapter to the typed DataTable foundation. A units
column now has a compact unit-aware type label, displays only the visible
numeric slice, and accepts strict edits in either the column's unit or a
compatible UDUNITS unit. The column's original class and unit metadata remain
the assignment invariant.

## Root cause

The A1 type-handler registry did not recognize class `units`. Such columns fell
through to the unsupported-object handler: they were read-only, had no unit
metadata in `column_info()`/`show_types`, and could be formatted as generic
objects. Treating the stored vector as an ordinary double would also have lost
the unit semantics and mishandled affine temperature conversions.

## Implementation

- Added `units` to `Suggests`; it remains optional and is not imported at package
  load time.
- Added a units handler to `R/datatable-typed.R`. It uses
  `units::deparse_unit()` for labels and `base::units()` to retain the prototype
  unit.
- Formats only the values passed from the current DataTable slice by applying
  `units::drop_units()` to that slice. Unit symbols stay in the type label.
- Parses numeric text plus an optional unit through `units::set_units(...,
  mode = "standard")`; no conversion factors or unit registry were added to
  termr.
- Rejects conversion warnings/errors, finite overflow, and conversions that
  fail a round trip to the input unit within a 32-double-epsilon relative
  tolerance. Failed parsing/casting happens before assignment.
- Uses vctrs casting/assignment when available, with a class-and-attribute
  checked base replacement fallback when vctrs is absent.
- Keeps `NA`, `NaN`, `Inf` and `-Inf` distinct. The NA edit is built in the
  prototype's unit.

## Files changed by A2.1

- `DESCRIPTION` — optional `units` suggestion.
- `R/datatable-typed.R` — units handler, formatter, parser, range/precision
  validation, typed NA and assignment fallback.
- `R/widget-datatable.R` — routes automatic units formatting through the
  typed visible-slice formatter.
- `docs/data.md`, `NEWS.md` — behavior and optional UDUNITS system dependency.
- `tests/testthat/test-datatable-units.R` — conversion, rendering, error and
  invariant tests.

The existing public API and `NAMESPACE` were not changed for A2.1. No generated
Rd file was edited. R CMD check verified namespace, documentation entries,
Rd usage and code/documentation consistency.

## Build and check

The final source archive is `termr_1.0.1.tar.gz` in this audit directory. Logs
and check artifacts are retained beside this report. Windows source builds of
`units` use the CRAN binary in the isolated task library; Linux/macOS source
builds need UDUNITS-2 development files (`libudunits2-dev` on Debian/Ubuntu,
`udunits` on Homebrew).
