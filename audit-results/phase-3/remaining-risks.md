# Remaining risks and unchecked areas (after phase 3)

## Open items (none is a confirmed defect in the shipped logic)
1. **SIGTERM / SIGHUP leave the terminal in raw mode** on the alternate screen (phase 1, S-3). R code cannot catch these signals.
   Recommended user-side recovery: `trap 'stty sane; printf "\033[?1049l\033[?25h\033[?1000l\033[?1006l\033[?2004l"' TERM HUP`
   in a wrapper script, or run `reset` / `stty sane` after the process. Documentation of this limit is still missing from
   `docs/terminal.md` and `docs/ssh.md`. I did not add signal handling (no reliable mechanism exists in pure R).
2. **Optimization O-1 is rule-based.** It is correct for the layout algorithms and widgets in this tree (differential tests, 8k+
   suite) but would silently become wrong if a new container starts using child content width outside `natural_width()`/`measure()`.
   The guard is `test-input.R` ("input edits keep incremental output identical...").
3. **Tree construction cost** is the largest remaining scalability limit (about 4 s for 3000 widgets, super-linear). Not profiled deeper.
4. **Focus changes (`tab`) still run a full layout.** The headless cost is mostly the R-level VirtualTerminal; real-terminal cost unmeasured.
5. Phase 1's S-2 (`wait_until_exit` with a ~1e-12 interval loops ~forever) and S-4/S-5 (Ctrl+D ignored; PTY drain speed) unchanged.
6. `test_app(width = .Machine$integer.max)` still allocates a screen of that width (not run to completion; not a supported size).

## Not verified in phase 3
- macOS; real terminal emulators (glyph rendering, fonts); independent emulator (pyte not installed in WSL).
- DBI/RSQLite functionality (the test run was declined by the user; the packages are unpacked only in a scratch directory outside the project).
- PDF manual and vignettes in `R CMD check` (check ran with `--no-manual --no-build-vignettes`).
- Comparison against the previous stable release (v1.0.1) was not performed; before/after numbers compare this tree before and after O-1.
- `profvis` interactive flame graphs (Rprof was used); `bench::mark` allocation tables (obj_size/gc used instead); `tracemem`.
- Real-time, hours-long sessions with workers, toasts and notifications; the 100k-event run used the simulated clock.
- Windows ConPTY was not re-run in phase 3 (no change touches the Windows driver); the WSL PTY checks and 40-seed crash hunt were re-run on the final code.
- Coverage was not re-measured after phase 3 (phase 1: 86.5%); touched lines are exercised by the new tests (mutation check for O-1).
