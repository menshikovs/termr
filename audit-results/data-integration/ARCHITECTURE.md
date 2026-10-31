# A3.5 architecture audit

## Scope and evidence

This audit inspected the working tree recorded in `BASELINE.md`, the current data source and DataTable code, its tests and documentation, and executed Windows and WSL validation. Earlier A1/A2/A3 files were already uncommitted when the phase began. This report does not treat a phase label as proof of implementation. The current package metadata still reports version 1.0.1.

## Data paths

### Local tables

`data_table()` accepts data frames (including tibbles and dplyr grouped/rowwise data frames) and matrices. The local path normalizes input with `as_table_data()`, builds per-column typed specifications/prototypes, and keeps the table data in R. Sorting and filtering operate over this local data and search formats values through the typed formatter. Paint formats the rows and columns in the current viewport; the table does not pre-format every cell at construction.

Grouped and rowwise edits are covered by tests. Group keys and rowwise grouping metadata are checked after edits. This remains an in-memory table, so a local filter/search can traverse local vectors and does not become backend pushdown.

### Lazy table sources

`table_source()` is the experimental synchronous callback protocol. `data_table()` validates the exact row count and names, requests an initial schema sample of at most 100 rows across the source columns, stores an empty typed schema frame, then requests row pages as needed. Paint requests only visible columns. A cached wider projection for the same page may satisfy a narrower request.

Each page must be a data frame of the requested size and column names. Later pages are checked against the initial per-column storage type, attributes, and S4 slots. The comparison ignores vector names and content-dependent `sfc` `bbox`/`n_empty` metadata. A mismatch is surfaced as a source error rather than allowing later rows to change the column type under the formatter.

The source protocol exposes optional sort, filter, search, stable row key, edit, refresh, close, and error callbacks. Missing callbacks are reported as unsupported; DataTable does not silently collect or scan the source to emulate them. Source errors can be rendered by `on_error`; recovery is explicit through a subsequent successful read/refresh.

### Built-in database paths

`db_table_source()` is an optional DBI/RSQLite table adapter. It quotes identifiers, binds filter values, applies supported filters and sort in SQLite, and fetches selected columns with bounded `LIMIT`/`OFFSET`. Its connection is borrowed by default; only `owned = TRUE` disconnects on close.

`db_query_source()` is read-only. Its built-in pager is SQLite-specific: column discovery and a `COUNT(*)` are done at creation, the count is cached until refresh, and page requests use bounded `LIMIT`/`OFFSET` against a wrapped query. A generic DBI driver can supply explicit schema/count/page callbacks. The wrapper does not rewrite user query semantics to push sort, filter, or search into the query. Closing the source marks the source closed but leaves the caller-owned connection open.

## Materialization boundaries

- The 10-million-row stress case used a mock callback. Construction fetched 100 schema rows and a distant viewport fetched only its needed 100-row pages. No 10-million-row object was created.
- Query row count may execute a database count query. It is cached and is not recomputed during paint.
- Direct `tbl_lazy`, Arrow `Table`, and Arrow `Dataset` values are rejected with a data-frame/matrix contract error. Tests confirm termr does not call `collect()` or convert the Arrow object implicitly.
- `data_profile()` rejects a lazy table source instead of scanning it. No built-in dbplyr, Arrow, or DuckDB adapter exists.

## A3.5 changes

The phase narrowed source page fetches to the current viewport projection and allows cache reuse for a narrower projection. It also added schema drift validation for later source pages, explicit reset of the schema when changing source, recovery coverage, backend rejection coverage, grouped edit regression coverage, and nonzero failure propagation in `tools/dev.R test`. `DESCRIPTION` imports the standard `methods` package to inspect S4 slots. No exported API or `NAMESPACE` entry was added by this phase.
