# 03 Test results

| Run | Env | Result | Log |
|---|---|---|---|
| Baseline `tools/dev.R test` (before any edit) | Windows R 4.6.1 | 8302 tests, 0 fail, 18 skip (DBI missing / POSIX-only), 5m18s | logs/baseline-test-win.log |
| After fixes `tools/dev.R test` | Windows | 8323 tests, 0 fail, 18 skip | logs/after-fix-test-win.log |
| After fixes, full suite (`TERMR_FULL_TESTS=true`) | WSL Ubuntu R 4.5.2 | 8432 tests, 0 fail, 4 skip (recipe Markdown) | logs/after-fix-test-wsl.log |
| `tools/pty/pty-check.py` (incl. new `combined_focus_session`) | WSL real PTY | all PASS | logs/pty-check-wsl.log |
| ConPTY e2e: hello, gate-form-escape, gate-hello-ctrlc, gate-handler-error | Windows ConPTY | 4/4 as expected (handler-error exits 1 by design); modes restored | logs/conpty-*.log |
| ConPTY Unicode app 10x5 / 80x24 / 200x60 with keys, resize, Ctrl+C | Windows ConPTY | 3/3 clean exit, modes restored | logs/conpty-uni-*.log |
| PTY fuzz (7 sizes, random key batches + resizes, Ctrl+C, signals) | WSL pexpect | found B-1 (crash), S-3 (SIGTERM/SIGHUP) | logs/pty-fuzz-wsl.log |
| PTY crash hunt, 70 seeded runs after B-1 fix | WSL pexpect | 0 crashes (before the fix: 4 of 25) | pty/crashhunt.py |
| Differential fuzz, incremental vs full render, 120 seeds x 50 ops (keys, resize, text, hide, type; wide/emoji/ANSI text) | headless | found B-2, B-3; after fixes 0 mismatches | diff-fuzz.R |
| Widget matrix: 24 widget kinds x 8 texts x 8 sizes (1x1..30x5), random keys + resize | headless | no genuine errors (notes below) | widget-matrix.R |
| KeyParser byte fuzz: 4000 cases (invalid UTF-8, truncated CSI, paste, random chunking) | headless | 0 errors/warnings, nothing pending | parser-fuzz.R |
| Lifecycle stress (remove in handler, exit twice, interval self-cancel, 300 mount/remove, 50 push/pop screens, failing worker) | headless | all PASS, memory flat (+0.2 MB) | lifecycle-fuzz.R |
| lintr, correctness-relevant linters on R/ | Windows | 56 style-only findings, none semantic | - |
| `R CMD check` (tarball from clean tree copy, `--no-manual`) | Windows | see final section in 09 | logs/rcmdcheck-final.log |

Notes: widget-matrix "select" mismatches were a harness artifact (`compose_frame(a$screen)` when the dropdown popup is the top screen);
`kv`/`progress` errors were wrong arguments in my harness. Existing tests were not modified; new tests were only appended.
