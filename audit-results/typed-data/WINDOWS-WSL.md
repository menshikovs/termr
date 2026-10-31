# Windows and WSL validation

| Check | Windows 11 / R 4.6.1 | Ubuntu WSL / R 4.5.2 |
|---|---|---|
| Full extended `testthat` suite | PASS — 14,104 passed, 58 skipped | PASS — 14,342 passed, 28 skipped |
| Typed DataTable and optional adapters | PASS; hms/bit64/dplyr skipped because absent | PASS; DBI/dplyr/hms/bit64 cases executed |
| UTC typed tests | PASS | PASS |
| America/New_York / DST typed tests | PASS | PASS |
| `R CMD build` + `R CMD check` | PASS tests/examples; 1 existing mirai warning and 1 note | PASS tests/examples; same warning and note |
| Install without optional packages | PASS in isolated library; base-R type assignment exercised | Covered by Windows isolated install |
| Existing PTY integration | Windows driver tests pass in full suite; POSIX PTY is skipped | PASS: `python3 tools/pty/pty-check.py`, all checks |

The check tarballs were built from a temporary copy of the current package
sources with large locally ignored `tools/` and `audit-results/` directories
omitted. `.Rbuildignore` now excludes local `.agents` and `.serena` metadata so
they do not enter a package tarball.

Windows child-process tests and WSL require access outside the sandbox in this
host. Both were run with the required process and WSL access. No changes were
committed or pushed.
