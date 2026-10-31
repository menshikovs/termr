# E-FIX — Windows Wsl

| Check (fresh E-FIX run) | Windows R4.6.1 | WSL Ubuntu R4.5.2 |
| --- | --- | --- |
| App testthat |115 PASS,0 fail/error/skip/warn |115 PASS,0 fail/error/skip/warn |
| Full core testthat |17,238 PASS,56 SKIP,0 fail/warn |18,736 PASS,2 SKIP,0 fail/warn |
| R CMD build/check |exit0 / Status: OK |exit0 / Status: OK |
| Real terminal |Native ConPTY all three apps PASS |POSIX PTY all three apps PASS |
| Shiny browser |Windows R server + real Chrome PASS |WSL R server + real Windows Chrome PASS |
| Processx / analysis |New runs PASS; see run-summary.json |New runs PASS; see run-summary.json |

Package metadata remains1.0.1 on branch2.0-termr. Actual namespace paths in every
runtime.json are current-windows/termr or current-linux/termr after the fix;
baseline pre-fix records show the different pkgload source path. Fresh installs
come from the current checkout, not the earlier H3 archive. mirai2.7.3 is used
with nanonext1.10.3 on Windows and1.10.4 on WSL; inkr is0.1.0. Browser dependencies
and paths are recorded per web process. Pywinpty3.1.2 was installed only into the
project's ignored Python directory, using a binary wheel. No global package,
core dependency, version, Git index or branch was changed.

Windows inherited unsupported LC_*=C.UTF-8 categories and emitted startup
warnings before app code. The original process fell back to locale C, which
corrupted Unicode when external app files were read with native encoding. Final
bootstrap selects supported .UTF-8 for LC_CTYPE in the R process and reads files
with explicit UTF-8. Actual final runtime.json records utf8=true; native and web
assertions require Tokyo characters. No system/user setting is edited. Check
shells clear invalid inherited variables before R startup; raw normal runs retain
startup warnings emitted before bootstrap. The earlier bad-locale lintr failure
is retained; the final proof scan runs after process-local normalization.
WSL ran C.UTF-8 normally. No blanket Unicode success is inferred from ASCII UI.
Windows absent optional typed packages remain absent and their core paths skip;
those skips are not successes. R CMD check uses --no-manual --no-build-vignettes
and _R_CHECK_FORCE_SUGGESTS_=false; PDF/manual/vignette validation is not claimed.

`preservation.json` verifies all initial615 files still exist, only scoped
application/tool files changed, core/man/API/H1/H2/H3 bytes remain unchanged,
Git index/HEAD remain unchanged, and both current source archives match374
R/man/test/metadata inputs. Applications/runtime/audits are excluded from builds.
git diff --check exits0; pre-existing CRLF advisory messages are retained.
