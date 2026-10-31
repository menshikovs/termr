# A2.4 known limitations

- Binary columns and blob/list values are read-only. There is no hex editor.
- The interface shows an eight-byte preview and total size, but no paged
  offsets/ASCII hex inspector. Existing row details are generic property
  content rather than a byte inspector; they now use the same safe summary.
- `list<raw>` is inferred by sampling at most the first and last 500 values.
  If raw appears only outside that sample, `column_info()` may report `list`,
  though a visited raw element still gets a byte-count/hex summary.
- Raw vectors used as DataFrame columns are byte-valued vectors, so each table
  row contains one byte. To store one multi-byte binary value per row, use a
  list column or `blob`.
- The Windows environment lacks `blob` and cannot reach the CRAN package
  index. The real package integration is tested in Ubuntu/WSL, where `blob` is
  available; Windows exercises the dependency-free list-of-raw adapter.
- A POSIX PTY test is not available in the Windows host process. WSL execution
  and platform checks are recorded separately in `TEST-RESULTS.md`.
