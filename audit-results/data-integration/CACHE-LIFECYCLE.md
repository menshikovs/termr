# Cache and source lifecycle

Source-backed tables use an LRU with a fixed 32-page entry limit. Pages are keyed by page window and fetched column projection; a cached superset for the same window can satisfy a narrower request and is promoted in LRU order. The cache is bounded by entry count, not by bytes, so a wide or large-class page can still consume significant memory.

Cache entries are discarded when the source is replaced, a delegated sort/filter changes the view, a cell edit is accepted, or the table is refreshed. Fetch errors are counted in source statistics. A later successful fetch clears the query source's current error state; explicit refresh clears cached rows before rendering current data again.

`$close()` is explicit. Removing a widget does not automatically close the source. `db_table_source()` borrows its connection unless `owned = TRUE`; the query source always leaves connection ownership with the caller. Closing a query source makes future reads fail but does not disconnect the DBI connection.

`source_stats()` reports fetch calls, rows requested/rendered, cache hits/misses, cells rendered, and fetch errors. It is instrumentation for diagnosis, not a promise of byte-level accounting.
