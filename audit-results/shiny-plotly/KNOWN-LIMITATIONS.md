# Known limitations

- Experimental process-local API; one receiver per Shiny R process, no broker,
  server-wide registry, cross-process sharing or durable replay.
- Pub/sub is lossy latest state. Gaps are visible; resync recovers current state
  only. Windows 100 Hz minute run had six skipped sequences. Native buffers,
  observation history and application graph commands are bounded.
- R is single-threaded here. Slow validators/callbacks/ggplot draws delay the
  whole process. The dashboard batches at 500 ms by default; 50 ms with 20
  real tabs overloaded this environment. Background browser RAF throttling
  can make its visible updates much slower than the producer.
- One graph command remains pending until the browser acknowledges. A failed
  or non-acknowledging widget stops graph delivery until recreated; no unbounded
  retry queue is added. Status and healthy sessions continue at available CPU.
- Browser/native websocket/Plotly internals are third-party; the application
  bounds its own pending commands, retained frames and probe samples.
- Local payloads without source/sequence cannot support cross-process dedupe;
  timestamps need clock agreement. Missing metrics stay NA, never zeros.
- Loopback is not authentication or encryption against other local processes.
  Windows publisher→WSL localhost is unavailable in this topology; firewall
  profiles were observed, but no rule-level root cause was asserted or changed.
- Native partial-env crash is reproducible and avoided by preserving current
  environment. The exact missing variable/native failure path remains unknown.
- Current browsers with native typed arrays; complete Shiny assets required.
  Probe timestamps approximate completion after two animation frames, not GPU
  presentation. Real collector configured interval includes sampling overhead.
- Minute-scale RSS observation is not a long soak, memory-leak proof, stress
  certificate, concurrency capacity guarantee or browser heap profiler.
- Windows terminal GUI/ConPTY checks were not automated here. Existing Windows
  driver unit tests and WSL real PTY suite passed; no macOS terminal was available.
