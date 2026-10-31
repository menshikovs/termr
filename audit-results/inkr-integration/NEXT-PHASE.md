# Next phase readiness

The termr bridge, public API, docs, examples and optional-free/enabled tests are
implemented. Windows and WSL focused tests, full suites, package checks and the
Windows benchmark are recorded in `TEST-RESULTS.md`, `PERFORMANCE.md` and
`WINDOWS-WSL-MACOS.md`.

Follow-up work can start without manual repository preparation. A next phase
should only expand the mapping if termr has a documented property equivalent,
and should re-evaluate inkr session caching if a future inkr version removes the
wide-sibling allocation behavior. No commit, push or release was performed.
