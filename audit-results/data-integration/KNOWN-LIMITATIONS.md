# Known limitations after A3.5

1. Source row counts must be exact, available up front, and no larger than `.Machine$integer.max`. Unknown/estimated totals are not represented in DataTable navigation or scrollbar semantics. The numeric contract rejects missing, non-finite, fractional, and over-limit values, but termr cannot detect a provider that supplies a rounded estimate as an integer.
2. Source callbacks are synchronous. There is no cancellation, async page load, backend back-pressure, or built-in retry policy.
3. The schema sample reads up to 100 rows across all columns; high-dimensional sources still pay this bounded but potentially wide initial read.
4. Cache size is bounded by 32 entries rather than bytes. Large/wide page objects can have a high memory footprint.
5. Only SQLite/RSQLite table and query pagers are built in. Other DBI drivers require explicit adapter callbacks. dbplyr, Arrow, and DuckDB adapters are absent.
6. Query mode is read-only and does not push sort/filter/search into a supplied query. Table-source operations need corresponding callbacks.
7. `LIMIT`/`OFFSET` can be expensive at large offsets for some backends. The 10M test is a callback mock, not a database benchmark.
8. Source edit transactionality and durable write semantics belong to the caller's `set_value` implementation. Built-in SQLite sources do not enable editing.
9. Local cell edits can copy a large R vector under copy-on-modify. Edit allocation was measured, but peak resident memory and garbage-collection pressure were not.
10. A2.3 lubridate types remain unestablished in this repository; their presence in the WSL library is not evidence of termr support.
11. Native terminal behavior is not established by headless testthat. WSL PTY binary/control/Unicode checks passed; Windows did not receive a native POSIX PTY test.
