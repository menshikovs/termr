# Known limitations

- Experimental latest-value transport; lossy pub/sub, no durable history,
  transactional publication or guaranteed per-event delivery. Gap recovery
  restores current state, not missing events. A slow callback delays its own
  polling process. Both owners must explicitly poll.
- JSON limits R type fidelity. NULL before publisher attachment at history=0
  cannot be distinguished from an empty local stream. Attach before emitting
  when every initial event matters. Existing non-NULL latest values seed.
- No authentication, encryption or non-loopback endpoints. Local processes
  are not authenticated. Windows/WSL forwarding varies by host: WSL->Windows
  succeeded here (including restart); Windows->WSL localhost did not connect.
- nanonext >=1.10.0 is required; actual validation used 1.10.3. Other supported
  versions were not installed or certified. NNG's native implementation is an
  optional external dependency; all new termr code remains R.
- Windows R 4.6.1 dev-loaded child processes using pkgload reproducibly exited
  with native access violation after receiving data and closing; installed
  package peers exited cleanly without trace, added sleeps or explicit GC.
  The integration harness therefore tests installed runtime peers. This
  observation does not prove the underlying native/dev-loader cause. Logs
  and the minimal raw-only control are retained for reproduction.
- Windows default millisecond sleeps resolve more coarsely on this host.
  Measured fan-out latency includes R timer/poll scheduling and codec work,
  not only NNG network latency. Benchmarks ran on a shared host under validation
  load and are not hardware-isolated performance guarantees.
- Collector process details are a bounded sample of 100 PIDs, sorted within
  the sample by RSS, not the globally largest 100 processes. Full ps::ps scans
  were observed to stall Windows collection around 4.6 seconds; bounded
  PID/name/RSS querying fixes that avoidable stall. OS APIs remain synchronous.
- Shiny is absent in the Windows R library. Shiny was exercised in WSL. New
  TUI checks use headless App/renderer; no manual Windows terminal/browser,
  SSH, macOS or arbitrary terminal host is certified by this run.
- R CMD check uses --no-manual, without PDF/TeX or CRAN incoming validation.
  Scratch installs and reports are excluded from source package builds.
