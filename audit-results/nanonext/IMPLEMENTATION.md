# Phase 3 implementation

## New maintained files

- R/transport_nanonext.R: two optional experimental constructors, private
  bounded codec/schema/endpoint helpers, raw pub/sub and async snapshot RPC.
- man/nanonext_transport.Rd: roxygen-generated reference; NAMESPACE adds
  termr_nano_publish and termr_nano_connect. `Rscript tools/dev.R doc` was
  run in WSL. The older roxygen version reformatted unrelated R6 help; those
  changes were restored from the Phase-3 baseline, preserving prior help edits.
- tests/testthat/test-nanonext.R: codec, endpoint, port ownership, source,
  snapshot/event ordering, slow readers, final-event recovery, corruption,
  topic prefix separation, restart and close/AIO cleanup tests.
- tests/testthat/fixtures/nano_child.R: trusted independent-process fixture
  for installed runtime peers, raw-only measurement and monitor lifecycle.
- tools/nanonext_integration.R: independent 1/10/50 subscriber fan-out driver,
  bounded readiness synchronization, deadlines, cleanup, logs and summaries.
- inst/examples/system-monitor-live/subscriber.R: standalone telemetry client.
- docs/nanonext.md: public API, protocol, safety, scheduling and launch guide.

## Modified maintained files

DESCRIPTION adds nanonext >=1.10.0 to Suggests; no Imports/Depends change.
README, NEWS, docs/data-streams.md, docs/stability.md and docs/api-inventory.md
document/classify the new exports (158 exports total).

The existing monitor common.R selects file or nano clients; collector.R
selects file/nano/both publishers and pumps transport independently between
samples. TUI/Shiny use 50 ms polling in nano mode while preserving file mode.
README documents four independent owners and environment configuration.
No metrics collector is duplicated; the existing file envelope is unchanged.

An observed Windows bottleneck was fixed in common.R: ps::ps() gathered full
metadata for every process and stalled sampling around 4.6 s. Collection now
queries PID/name/RSS only, capped before queries at 100 PIDs. Records are a
documented sample sorted by RSS, rather than a global top-100 claim. Monitor
RPC timeout is 3 s to tolerate busy collection; failed access remains null.

R/streams.R, signals, workers, App, layouts, widgets, terminal drivers and
previous tests are unchanged by Phase 3. Existing uncommitted code, docs and
Phase-0-2 artifacts were saved in baseline/ and initial-hashes.json. A final
preservation manifest distinguishes authorized Phase-3 edits from unchanged
original files. No Git commit/push/merge/release, no system software install.

## Validation infrastructure

nanonext 1.10.3 was absent initially. CRAN binary (Windows) and bundled-source
build (WSL) were installed only to workspace libraries under this audit.
No system NNG/C compiler installation or package-library modification was
performed. R CMD check stages .Rbuildignore-allowed source entries to avoid
copying large existing ignored tools/audit artifacts before R's own filtering.
Tar listings assert audit/temporary files are absent.

Raw-only transport controls, latency/fan-out reports, codec/file/dispatch
benchmarks, minimal-without-nanonext installs, cross-OS forwarding/restart,
and actual collector/TUI/Shiny/independent-client lifecycle drivers are saved
here with logs. Windows dev-loader native shutdown failure was isolated from
installed runtime: real peers use library(termr), without trace/extra GC/sleep
workarounds. That unresolved dev-loader/native interaction is documented.
