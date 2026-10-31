# A2.4 implementation

## Scope

The typed DataTable now recognizes raw vectors and objects inheriting from
`blob`. Raw elements inside ordinary list columns receive the same bounded
binary summary. `blob` is declared in `Suggests`; termr does not call its
namespace, so raw and list-column support remains available when it is absent.

## Behavior

- A raw value is represented as a byte count and at most eight uppercase hex
  bytes. For example, `raw(0)` displays `0 bytes`, a one-byte value displays
  `1 byte: FF`, and longer values end with `...` after the preview limit.
- A raw column formats each row as one byte. A raw element in a list or blob
  displays the complete element size and a bounded preview.
- `NULL` list/blob elements display as `<NULL>` and remain missing for the
  missing filter. An atomic `NA` list element displays as `NA`; an empty raw
  vector is distinct and displays as `0 bytes`.
- `column_info()` reports `raw`, `blob`, or `list<raw>` where the latter can
  be inferred from the first/last sample. Types, classes and attributes of the
  data remain with the source column.
- Binary columns are read-only. Raw columns cannot be sorted. Existing
  missing and text filters operate on typed missing masks and safe summaries.
- `browse_data()`'s row details use the same compact summary. There was no
  byte-oriented cell inspector in the existing UI, so no second viewer was
  introduced.

No exported function, R6 class, or `NAMESPACE` entry changed.
