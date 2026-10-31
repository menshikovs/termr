# Platform validation

## Windows

- Windows 11 x64, R 4.6.1, UTF-8 session charset.
- Enabled and optional-free inkr focused tests passed.
- Full testthat: 15,270 passed, 0 failed/errors/warnings, 94 skipped.
- Windows `R CMD build` and `R CMD check --no-manual --no-vignettes` completed
  with `Status: OK` when `_R_CHECK_FORCE_SUGGESTS_=false`; check INFO names 15
  optional Suggests packages absent from the library.
- The first check attempt with default force-Suggests stopped before checks on
  absent optional packages. The first sandboxed full-suite attempt also hit
  Windows child-process permission errors; the full suite then passed outside
  the sandbox.
- Unicode, focus, renderer and widget-tree automated tests passed. No real
  interactive console session was exercised.

## WSL

- Ubuntu 26.04.1 LTS x86_64, R 4.5.2, UTF-8 session charset.
- Enabled and optional-free inkr focused tests passed.
- Full testthat: 16,846 passed, 0 failed/errors/warnings, 30 skipped.
- `R CMD check --no-manual --no-vignettes` ran under WSL R 4.5.2 and completed
  with `Status: OK`; the source archive was built by Windows R 4.6.1 from the
  same checkout. `_R_CHECK_FORCE_SUGGESTS_=false` allowed the absent optional
  `mirai` and `nanonext` packages and check reported them as INFO.
- Unicode, focus, renderer, POSIX terminal-driver and widget-tree headless tests
  passed. No real interactive PTY visual review was run.

## macOS

No macOS runner or machine was available in this workspace; macOS validation was
not run. No macOS result is inferred from Windows or WSL.

## Terminal rendering scope

Headless coverage verifies style resolution, Unicode-safe test output, geometry,
clipping and the existing color normalization path. It does not verify live
terminal-specific RGB/256-color capability negotiation, emulator-specific
Unicode widths, or alternate-screen lifecycle in an interactive terminal.
