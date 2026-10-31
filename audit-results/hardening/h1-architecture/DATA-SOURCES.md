# Data sources and schema contracts

Built-ins found in source are table_source(), db_table_source() for RSQLite,
and db_query_source() with a built-in SQLite pager and a caller-provided DBI
adapter protocol. No DuckDB/dbplyr/Arrow auto-adapter, source identity registry,
Arrow reader or collect() path exists. WSL tests construct dbplyr/Arrow objects
and verify explicit rejection; they do not demonstrate adapter support.

table_source requires an exact nonnegative whole count <= .Machine$integer.max,
unique nonempty names and data.frame page results. Unknown, estimated and
over-limit counts are rejected. Current docs/data-sources.md states the same
exact-count requirement, so the earlier documentation contradiction is resolved.

DataTable samples at most 100 rows across all columns to infer schema, then
projects visible columns and caches at most 32 pages. Reusing a wider cached
page is allowed. Later successful pages must preserve storage/class/type
attributes and S4 prototype slots; slice-dependent sfc bounds are excluded.
Unsupported source operations do not silently materialize or scan. Supplied
callbacks, initial counts and database queries are synchronous and may block UI.

F06 fixed a real collision in the concatenated projection key using byte-length
prefixes. The public regression switches from columns a,b to one column a-CR-b
at row 101 and checks that the resulting viewport contains 501.

F01 remains: set_data assigns .source and clears schema/cache before validating
row count/seed. A rejected replacement leaves old .data with the new invalid
source. This also clears edit provenance before success. Refresh delegates
source mutations before rebuilding state; callback-side transactions cannot
generally be rolled back by termr, so H2 must define the boundary explicitly.

SQLite identifiers are DBI-quoted and supported filters bind values; paging
uses bound LIMIT/OFFSET. Without requested sorting, queries do not promise a
stable SQL row order. Concurrent external writes and nonunique sorts can
change positions between pages. No snapshot transaction/stable row key is
created implicitly; this is a documented positional protocol limitation.

Source close is explicit. Changing a DataTable source does not close borrowed
sources automatically. Query sources never own the supplied DBI connection.
Custom non-SQLite DBI pagers are user code, not built-in feature coverage.
