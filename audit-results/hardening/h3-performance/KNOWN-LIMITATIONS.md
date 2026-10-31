# Known limitations

- Repeated sibling removal still searches/rebuilds the parent list quadratically;
  lifecycle callback observability prevents a casual bulk-detach rewrite.
- inkr session sibling insertion remains quadratic in the independent package.
  The existing stateless bridge is retained. Deep path prefixes still consume
  depth-dependent strings; global epochs and conservative layout invalidation
  remain broader than ideal.
- Continuous chart publication now performs more real redraw work. Max-points
  and queue caps remain unchanged; virtual time is not physical frame latency.
- Timings are instrumented and some jobs overlapped. Use min/max and allocation
  evidence; small timing differences are not established speedups. Windows
  timer resolution makes zero-duration cases unsuitable for ratios.
- Gross Rprofmem bytes exclude some small/external allocations. Peak process
  memory, keyboard-to-photon latency, fresh-process startup, dedicated OS handle/
  process/socket counts and exhaustive long-duration leak freedom are unproven.
- Local table sort/filter are global operations; bounded display does not make
  them constant time. A4 benchmark exports ten selected rows, not a full table.
- Optional dependency absences are listed per platform. No current mirai,
  nanonext or duckdb integration soak, macOS CI, real Windows console or network
  terminal latency run is claimed. No global packages were installed.

The reports describe measured coverage and unmeasured boundaries separately.
They do not equate successful check with complete Suggests/platform coverage.
