# E-FIX — Remaining Issues

No mandatory gate is FAILED in the final tested matrix. No H4 work was started.
The following limits remain explicit:

- The exact initial “no interface” symptom from the user's unspecified VS Code
  launch context was not reproduced using the root commands in real terminals.
  The confirmed cwd failure is repaired; the launcher and documentation explain
  terminal-vs-Output and web URL behavior. This is not proof of a specific editor
  extension's execution host or of every terminal emulator.
- Alt combinations were inconsistent in native ConPTY. F11/F12 are the tested
  primary bindings, with Alt aliases retained; no speculative core driver patch.
- Unsupported inherited Windows C.UTF-8 locale variables still produce startup
  warnings before R code. Bootstrap now normalizes process-local LC_CTYPE and
  explicit UTF-8 source loading; final glyph assertions pass. System/user settings
  are untouched. This was tested on Windows UCRT R4.6.1; older non-UTF-8-capable
  Windows R sessions fail explicitly rather than silently corrupting labels.
- One WSL append-log read returned ENODATA. Bounded read-only retries are logged;
  persistent failures still fail the test. No whole-scenario automatic retry hides
  application failures. Earlier exploratory failing results remain retained.
- Static audit resolves documented namespace signatures and selected receiver
  aliases; it is not a complete proof of arbitrary dynamic R behavior. Runtime
  gates cover the implemented operations. Default lint style debt remains.
- App coverage excludes instrumentation of remote worker compute; branches/core
  covr were not remeasured. Five-run benchmarks under concurrent load are
  descriptive; historical Phase E performance/coverage is not reused as evidence.
- Long-running native handle retention, arbitrary networks, macOS, other browser
  engines and stress beyond these bounded cases are not certified. Current
  cleanup/PID results do not resolve the historically reported handle concern.
- Windows optional typed fixtures remain conditional; unavailable packages are
  reported and their core tests skipped. No absent integration is labelled passed.
- DESCRIPTION still says1.0.1. Fingerprints identify current development source;
  this is not a release or a metadata claim that2.0.0 was published.

The package core and H1/H2/H3 tests are byte-identical to the E-FIX start.
No commit, push, merge, reset, clean, release or unrelated overwrite occurred.
The prior Phase E artifacts remain historical and were not used to certify
current startup. See preservation.json and git-status-after.txt for the exact
scope. Working applications and current isolated installs are present locally;
no manual code repair is required before running the documented commands.
