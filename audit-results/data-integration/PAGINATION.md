# Pagination behavior

- Source indices are one-based integer positions. The current source protocol requires an exact non-negative count no larger than `.Machine$integer.max`; unknown, estimated, or larger totals are rejected.
- Source reads are chunked in 100-row pages. A viewport crossing a page boundary may request two pages. `row_data()` and selected-cell access request only the necessary page/column projection.
- The initial prototype read is `min(100, row_count)` rows across all columns; zero-row sources request a typed zero-row frame.
- Scrolling to a distant row does not fetch intermediate pages. The 10M-row mock jumped to row 5,000,000 and fetched two pages (200 rows total) for the viewport.
- Sort/filter callbacks may change the source's current order/count. DataTable clears page cache and resets view/cursor state after accepted operations.
- Page responses are validated for exact row count, exact requested names/order, and stable per-column type/attributes/S4 slots.

No unknown-total scrollbar/navigation contract exists. The implementation therefore rejects a missing, non-finite, fractional, or over-limit count rather than showing a guessed total or pretending that the last loaded page is the end. A custom callback that reports a rounded estimate as an integer cannot be detected by termr; the provider must honor the exact-count contract.
