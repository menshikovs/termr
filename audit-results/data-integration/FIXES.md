# Fixes made during A3.5

| Area | Root cause / gap | Change |
|---|---|---|
| Source render projection | Paint fetched every source column even when only a narrow horizontal viewport was visible. | Paint now fetches the visible column projection; `source_read()` passes the requested columns, and a wider cached projection can satisfy a narrower same-page request. |
| Source schema stability | A later backend page could return another storage type or metadata, causing formatter/edit behavior to vary by page. | Added internal signature validation for storage type, attributes, and S4 slots; vector names and slice-specific `sfc` bbox/empty counts are ignored. |
| Source replacement | A previous source schema could remain relevant when a new source was installed before the next sample was fetched. | Reset schema before sample fetch on `set_data()` source path. |
| Error recovery coverage | Temporary read failure/recovery did not have a regression proving fresh typed values become visible after refresh. | Added source outage, refresh and successful typed-read regression. |
| Backend boundary coverage | No explicit tests demonstrated direct lazy dbplyr/Arrow inputs are rejected rather than materialized. | Added direct rejection tests; they run in WSL with those optional packages installed. |
| Developer test status | Test runner printed failure/error counts but did not set a failing process exit status. | `tools/dev.R test` now quits with status 1 for any failure or error. |

No new public function, exported symbol, dependency integration, or `NAMESPACE` entry was introduced. `methods` is imported for standard S4 slot introspection.
