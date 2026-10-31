# Editing safety

## Local data

`set_cell()` parses against the column prototype/type handler and assigns through the typed table assignment path. Unsupported classes can remain read-only. The original input object is not mutated; edits update the DataTable's own data copy. Existing grouped and rowwise tests confirm grouping metadata remains correct after edits, including an edited group key.

## Source-backed data

Editing is available only when all three conditions hold: the table is editable, the column specification marks the column editable, and the source provides `set_value()`. The incoming value is parsed against the initial schema prototype. The current cell is then fetched using a one-column projection, type-checked/assigned, and passed with a one-based source row and column name to the backend callback. A callback returning `FALSE` rejects the edit. Accepted edits clear the page cache and invalidate the view.

There is no built-in edit callback for SQLite table/query adapters. The adapter owns transactionality, concurrency checks, and durable storage semantics. No full-column fetch is needed to edit one source cell, although a local R vector edit can allocate/copy that vector under R copy-on-modify semantics.

## Guarantees and limits

- Later pages cannot silently change a column's storage type, class attributes, or S4 slots relative to the schema sample.
- Unsupported/non-round-trippable types must be read-only; editing does not automatically append labels or change source metadata.
- A backend callback is responsible for atomicity if it can fail after writing. Termr cannot roll back an external side effect from a callback.
- Cache invalidation occurs after the callback accepts an edit; the source should return `FALSE`/raise an error without partially committing when it rejects an edit.
