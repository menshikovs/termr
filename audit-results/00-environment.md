# 00 Environment

Audit date: 2026-10-29. Branch `feature/terminal-input-layout-1.1` (base `main`, HEAD d6ca75e), local working tree
including 24 modified + 2 untracked files (the object under test). Package version per DESCRIPTION: termr 1.0.1.

| Tool | Windows 11 | WSL Ubuntu |
|---|---|---|
| R | 4.6.1 (`C:/Program Files/R/R-4.6.1`; 4.5.2 also present but has no Rscript.exe) | 4.5.2 |
| testthat / R6 / pkgload / callr / processx | yes | yes |
| lintr, covr | yes | yes |
| profvis | yes | not checked |
| devtools | no (not needed; `pkgload` used) | not checked |
| tmux, pexpect 4.9.0, expect, asciinema, hyperfine, valgrind | no | **yes** |
| python | 3.14 (no pexpect/pyte on PATH) | python3, pexpect; no `pyte` |
| Windows ConPTY harness (`tools/e2e-windows.py`) | present, **not run** (needs pywinpty+pyte from `tools/validation-0.4`, see notes) | n/a |

DBI/RSQLite are not installed in either R library, so 16+ DB tests skip (as documented in project memory).

WSL copy of the working tree was installed to a scratch library (`~/audit/lib`) so the PTY harness tests the local code,
not an older installed termr. Nothing outside the project was modified; scratch files live in `audit-results/` and the
session scratchpad. `audit-results/` is not build-ignored by `.Rbuildignore`; all package builds in this audit were made
from a copy that excludes it. **Delete or add `^audit-results$` to `.Rbuildignore` before building the package.**
