# Reproducible R-code audit

R/reproducible-code.R builds calls/symbols/constants with language objects.
parse() is restricted to dput-emitted bare literals; arbitrary cell/filter
text is not parsed/evaluated during generation. Executable/reference-bearing
values fail the whitelist. Value export preserves double precision, integer64,
Haven tagged payloads and tested structured attributes. Limits are 1000 rows,
10000 cells, 1 MB source, 1000 edited cells and nesting depth 40.

Value mode serializes the selected bounded current value. Pipeline mode
describes the final filter/sort/columns/selection, not action history.
Edits mode records bounded original-row assignments, not remote writes.
The model marks source identity unknown and requires a caller-supplied data
binding. Source-backed pipeline/edits exports explicitly return unsupported.
Query strings, credentials and remote connection state are not exported.

F02 is confirmed even when the binding is exactly table$data: after editing
the sorted key 1 to 10, table$view is still 1,2,3, but the generated filter/sort
pipeline computes 2,3,1 and claims exact. This is a DataTable-view/export
integration error, not merely an unidentified external source.

New source assignment resets the edit ledger and view; failed assignment can
reset them before committing the replacement (F01). H2 must cover failure
rollback and edits affecting filters as well as sort keys. Existing tests
cover hostile names, source-row edit identity, unchanged input, limits, column
reorder/hide and typed round-trips but did not expose this combined path.
