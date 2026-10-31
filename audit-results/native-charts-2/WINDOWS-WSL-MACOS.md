# Windows, WSL, and macOS

## Windows

- Windows 11, R 4.6.1.
- `R CMD check --no-manual` on the staged package tarball, with `_R_CHECK_FORCE_SUGGESTS_=false`: **Status: OK**.
- The full package `testthat.R`, chart examples, generated Rd checks, and dependency/code analysis passed.
- Focused chart, stream, and example tests passed.
- Windows locale handling used the configured runtime after clearing inherited locale variables for R. Windows terminal input/parser tests ran as part of the full package suite; this is not a native interactive console certification.

## WSL

- Ubuntu 26.04 under WSL, R 4.5.2, `LANG=C.utf8`, `LC_ALL=C.utf8`.
- `R CMD check --no-manual` on the same package tarball, `_R_CHECK_FORCE_SUGGESTS_=false`: **Status: OK**.
- Full package `testthat.R`, examples, and documentation checks passed. The Unix PTY fixture and full PTY CI harness also passed on the final installed package after a complete rerun.
- WSL is not equivalent to a native Linux or macOS host.

An initial WSL run with all locale variables unset used the C locale, emitted UTF-8 parse warnings, and triggered ASCII fallback expectations in 58 unrelated tests. The final check used the installed `C.utf8` locale and passed. One first PTY run had two transient combined-input ordering failures; the complete immediate rerun passed all harness checks.

## macOS

No macOS host was available in this session. The repository's CI workflow defines a macOS R CMD check and PTY job, but no run against this uncommitted C1 worktree was available. macOS remains unverified here.
