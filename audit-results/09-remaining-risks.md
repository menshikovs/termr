# 09 Remaining risks and not verified

Not verified:
- macOS (no machine); other terminal emulators (iTerm, Windows Terminal rendering, tmux behaviour of wide glyphs). The PTY/ConPTY
  checks observe bytes and a virtual terminal, not real glyph rendering, fonts or visual snapshots.
- WSL has no `pyte`, so screen content in real PTYs was not parsed; assertions there were on escape sequences, logs and exit state.
- DB features (DBI/RSQLite not installed): about 17 tests skipped on both platforms.
- Valgrind was not run: the package has no compiled code (no `src/`), so it would only test R itself.
- profvis not used (Rprof was); no prior-version performance comparison; asciinema/tmux/Expect installed in WSL but not needed beyond pexpect.
- `R CMD check` ran with `--no-manual --no-build-vignettes`; the PDF manual and vignettes were not built here (see project notes on TeX).
- Resize while rendering mid-frame and key repeat on real terminals under load only approximated by PTY floods.
- Unfixed items: S-1..S-6 in 05-suspected-bugs.md (SIGTERM/SIGHUP not restoring the terminal is the most user-visible).
- The fuzzers are seeded but PTY timing is not deterministic; the crash B-1 was reproduced headlessly from the recorded input.

Workspace hygiene:
- `audit-results/` is untracked and **not** in `.Rbuildignore`; build packages only from a copy that excludes it, or add `^audit-results$`
  to `.Rbuildignore` (not done, out of scope).
- The check log earlier showed hidden dirs `.agents`/`.serena` in the working tree (ignored by git, excluded from my final build).

## R CMD check (final, after all fixes)
Windows, R 4.6.1, tarball built from a clean copy of the working tree: **Status: OK** (0 errors, 0 warnings, 0 notes), including the
full testthat run. An earlier run of the same procedure on a copy that still contained `.agents`/`.serena` gave 1 NOTE (hidden files);
this is local environment clutter, not the package.
