# DataTable Source Architecture & Atomic Replacement

`DataTable` supports two data source modalities:
1. **In-Memory Data Frame**: Full local data frame with vectorized sorting, filtering, selection, and editing.
2. **Lazy Table Source (`table_source`)**: Bounded page-by-page fetching suitable for large remote databases (RSQLite, PostgreSQL) and custom pagers.

## Atomic Replacement Implementation
When `DataTable$set_data(new_source)` is called:
- If `new_source` is an invalid object or fails during `row_count()` or `get_rows()`, the call aborts without altering `private$.source`, `private$.data`, `private$.specs`, or the view cache.
- Existing edits and selections are preserved on failure.
- When replacing with a valid new source, schema discovery and initial page seeding succeed before the old source is discarded, ensuring atomic state transition.\n