# Windows and WSL observations (2026-10-29)

Windows R 4.6.1 UCRT; WSL Ubuntu 26.04.1 R 4.5.2; nanonext 1.10.3 on both.
Only 127.0.0.1 TCP listeners were used. All tests were run in this environment;
no claims are borrowed from previous CI or prior phases.

| Scenario | Result | Restart / loss behavior |
| --- | --- | --- |
| Windows publisher -> Windows subscriber | PASS, 1/10/50 independent clients | Latest-state recovery, slow-reader gaps; monitor/TUI/source restart PASS |
| WSL publisher -> WSL subscriber | PASS, 1/10/50 independent clients | Latest-state recovery, slow-reader gaps; monitor/TUI/Shiny/source restart PASS |
| WSL publisher -> Windows subscriber, loopback forwarding | PASS | Publisher restarted on the same endpoints; Windows subscriber accepted new source and continued |
| Windows publisher -> WSL subscriber, loopback | DID NOT CONNECT within bounded 8 s attempt | No successful session, so reconnect not certified for this direction |

Cross restart endpoints: see cross-restart/RESULT.json; the OS allocated live
and snapshot ports remain recorded there. Median observed cross-OS callback
latency was 7.00 ms, p95 25.89 ms, p99 37.14 ms. This includes R polling and
JSON work, not only network transit. The standalone direction attempts record
endpoints, both R versions, nanonext version and diagnostics in
wsl-to-windows/RESULT.json and windows-to-wsl/RESULT.json. No LAN-host address,
wildcard bind or firewall change was attempted to force reverse connectivity.

Each fan-out SUMMARY.json records exact endpoints, source ID, platform,
version, elapsed time, per-client latency, gaps, retained history, pending
operations and RSS. Main logs are fanout-{windows,wsl}-{1,10,50}.log, with
the final one-client logs suffixed -final where applicable. All clients use
actual installed termr runtime peers; socket ports are bound via port 0 and
discovered without releasing ownership.

Both minimal-without-nanonext installations load termr, emit/inspect a local
stream, render a headless TUI and return a clear optional-dependency error
when a nano adapter is requested. Windows Shiny is unavailable, so WSL
provides Shiny server integration. No global R-library/system installation.

Windows invalid inherited C.UTF-8 locale is cleared for tests (LC_ALL and
LC_CTYPE empty, LANG=en). Windows processx/WSL service operations require
approved execution outside the sandbox. These are environment constraints,
not evidence of an API failure. New interactive terminal/browser/manual host
testing was not performed; headless/render and process tests are distinct.
