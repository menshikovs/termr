# Recommended next phase

1. **Row-count contract:** design unknown/estimated counts, end-of-data discovery, navigation, scrollbar semantics, and count refresh explicitly. Preserve the invariant that the UI never fabricates an exact total.
2. **Backend adapters:** implement and test opt-in dbplyr, Arrow Dataset/record-batch, and (if required) DuckDB adapters that push projection and paging down and avoid full collection. Specify exact-count cost and type/schema metadata for each backend before adding them.
3. **Lifecycle and async reads:** define cancellation, pending/error/retry state, concurrent viewport requests, and source close ownership before adding asynchronous fetching.
4. **Editing protocol:** define atomicity, row-key identity across sort/filter, stale-write detection, and conflict/error recovery. Keep the existing query adapter read-only until this contract exists.
5. **Cache accounting:** add byte-based cache limits or configurable page/cache budgets for wide/large typed pages and benchmark evictions.
6. **Type coverage audit:** complete A2.3 lubridate support or explicitly defer it. Continue testing all optional type handlers through both local and source-backed page paths.
7. **Performance baseline:** preserve repeatable before/after timings for constructor, render, scroll, source fetch, and one-cell edit, including memory/peak allocation metrics and backend latency separately.

A3.5 does not claim that the missing lazy backend, unknown-row-count, or async contracts are solved. The current code and tests make these boundaries explicit so follow-up work can start without relying on a silent full-table fallback.
