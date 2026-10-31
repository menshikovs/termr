# Known Design Limitations & Non-Defects

1. **Native Chart Stream Drain-Only Render Policy**:
   - Backlog bursts yield in 16-record batches to allow terminal repaints, but chart rendering is finalized when the queue drains to avoid continuous intermediate layout thrashing.
2. **Reproducible Code Whitelist**:
   - Only whitelisted data types (standard R atomic types, factors, dates, difftimes, and supported packages like `haven`, `units`, `sf`, `blob`, `bit64`) can be exported as exact code. Arbitrary user S4/S3 objects return `status = "unsupported"` by design.
3. **Lazy Paging on Non-SQLite Drivers**:
   - `DataTable$set_data` with lazy SQL queries currently provides built-in pagination for SQLite. Other DBI drivers require custom `table_source` adapters.
4. **Interactive Terminal Requirement**:
   - `default_driver()` requires an interactive terminal (`isatty(stdout()) == TRUE`). Headless testing must use `HeadlessDriver` or `test_app()`.\n