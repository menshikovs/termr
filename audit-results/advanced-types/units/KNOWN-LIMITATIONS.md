# Known limitations

- `units` and UDUNITS-2 remain optional. Without `units`, basic termr use is
  unaffected, but units-class columns are read-only because there is no safe
  parser/converter available.
- Building `units` from source needs UDUNITS-2 system files: typically
  `libudunits2-dev` on Debian/Ubuntu and `udunits` on macOS/Homebrew. Windows
  users can install the CRAN binary.
- Numeric edit input uses a period decimal separator, matching a strict R
  numeric representation; locale decimal commas are not accepted. A bare
  number means the column unit. Explicit unit text must be accepted by the
  installed `units`/UDUNITS version.
- Unit conversions use R doubles. Normal floating-point rounding is allowed
  within the documented relative round-trip tolerance. Conversions that
  overflow or lose the entered value on round trip are rejected, including
  values at subnormal extremes.
- Temperature offset semantics are delegated to `units`; unsupported or
  warning-producing conversions are rejected. No custom affine-temperature
  logic exists in termr.
- A scalar edit copies the underlying R column vector under copy-on-modify.
  The measured allocation is proportional to the source vector size even
  though parsing and conversion remain scalar. Avoiding that copy would require
  changing DataTable storage/ownership semantics.
- Compact type labels follow terminal display width. Very narrow columns may
  visually clip a long custom-unit label; `column_info()` retains the full
  unit label.
