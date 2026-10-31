# Binary safety

- Binary payloads are never passed to `rawToChar()`, character coercion, or
  UTF-8 decoding. The formatter converts only the first eight raw bytes to
  integers and formats those numbers as uppercase hex.
- ESC (`1B`), NUL (`00`), `FF`, malformed UTF-8 and all other bytes therefore
  become printable ASCII digits and letters. Arbitrary bytes cannot reach the
  terminal renderer as control sequences.
- The preview has a fixed eight-byte limit regardless of payload length.
  Formatting a visible table slice does not hex-encode the full source column.
- List/blob `NULL`, atomic missing values, empty raw vectors and non-empty
  raw values remain distinct (`<NULL>`, `NA`, `0 bytes`, and a size/hex
  summary respectively).
- No raw or blob edit parser was added. `set_cell()` rejects binary edits
  before assignment; source and table copies remain unchanged.
- No ASCII side panel or byte-offset navigation was added because there is no
  existing cell-level binary inspector. The row detail view displays only the
  bounded summary.
