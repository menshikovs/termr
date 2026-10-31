# Lazy evaluation and materialization

## Verified boundaries

1. Creating a source-backed DataTable reads no more than 100 rows for its schema sample. The sample requests all columns so typed prototypes can be established.
2. Painting and scrolling request bounded row pages (at most 100 rows per fetch) and only currently visible columns. The 10M-row mock did not generate its full data set.
3. Source sorting/filtering/searching is only delegated when a callback is present. No source callback means a clear unsupported-operation error, not a client-side collection.
4. SQLite query counts are computed once at source creation and again only on refresh. Repainting does not issue a new count.
5. A direct dbplyr lazy table, Arrow Table, or Arrow Dataset is rejected. Regression tests use `expect_error(data_table(x), ...)`; no `collect()` is part of the path.
6. `data_profile()` explicitly rejects a lazy source rather than trying to profile every row.

## Costs that remain

- The schema read is bounded by rows but grows with the number and width of all columns.
- Exact count for an arbitrary query can be expensive even if it does not materialize result rows. SQLite query source computes it once at creation.
- `OFFSET` paging can become slower at large offsets depending on the backend/query plan. The mock benchmark measures termr fetch/render overhead, not database query-plan cost.
- All callbacks are synchronous. There is no cancellation, asynchronous fetch, back-pressure, or estimated-total mode in DataTable source mode.

## Backend-specific findings

The current table adapter is SQLite/RSQLite. `db_query_source()` permits a caller-supplied DBI adapter with explicit column names, exact count, and page reads. No built-in dbplyr, Arrow, DuckDB, or generic record-batch adapter was found. WSL has dbplyr and Arrow installed; those objects are rejected without implicit collection. DuckDB is absent and was not exercised.
