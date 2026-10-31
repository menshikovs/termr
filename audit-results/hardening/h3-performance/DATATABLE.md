# DataTable and virtual sources

R/widget-datatable.R and the typed handlers are unchanged by H3. Broad CSVs
measure local tables at 1,000, 100,000 and 1,000,000 rows with integer/double/
character columns: construction, first render, distant scroll, sort, predicate
filter, resize, scalar edit, row lookup, selection and bounded A4 value export.
Export explicitly selects ten rows; it is not a full-million-row code export.
Sort/filter legitimately inspect local data; virtualization claims concern
display formatting and lazy-source requests, not those global operations.

The lazy fixture has 10,000,000 rows and 40 columns; width 109 shows 12 columns,
pages contain 100 rows and the existing FIFO capacity is 32. It visits 40 distant
positions. *-source-requests.csv records every projection and request count;
the initial bounded schema sample reads all 40 columns. Later viewport requests
read 12 columns. Before: 8,100 rows requested, 480 rendered, 5,760 cells rendered.
There is no full collect. A second dedicated resource-cycle test asserts cache
size <=32 through repeated source switches and renders.

Focused/full suites exercise typed attributes, optional units/haven/lubridate/
blob/sf/vctrs handlers, source paging/projection, schema rejection and atomic
replacement, edits, sorting/filtering and exact A4 reproduction. Windows lacks
several optional packages; WSL supplies the broader type/DB matrix. No type
handler or source transaction was weakened to save an allocation.

Source cache-hit/projection collisions and failed-source recovery retain their
H1/H2 contract tests. Callback time remains synchronous; arbitrary DB latency
and network-backed paging are not bounded by these synthetic fixture timings.

Granular source-cache-hit and source-replacement rows separately measure a
prepared cached render and set_data of the same synthetic 10-million-row source
followed by render. This one-column fixture isolates cache/replacement overhead;
the 40-column/12-visible-column fixture remains the projection/scroll workload.
