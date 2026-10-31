# E-FIX — Root Causes

The user's reported symptom was “the interface did not open”, without an error
message or a specified mode. **The original root-directory startup failure was
not reproduced in this environment.** Before changing application code, all
three documented TUI commands rendered and accepted input in Windows ConPTY and
WSL PTYs. The original web entrypoint also rendered real Plotly/ggplot2 in Chrome.
Fresh `before-windows`, `before-wsl`, `before-web-windows` logs/runtime metadata
retain that evidence. This does not disprove the user's observation or identify
their particular VS Code launch context. Prior Phase E reports were not used as
proof of current functionality.

Confirmed defects/gaps, with failing-first evidence:

| Issue | Cause | Fix |
| --- | --- | --- |
| Startup outside repository cwd fails | run.R sourced bootstrap by relative cwd before resolving the project | Resolve entrypoint/project root, then source absolute bootstrap and restore caller cwd |
| Corrupt Windows Unicode labels | Unsupported inherited C.UTF-8 settings left R in locale C; app source used native encoding | Select supported UCRT UTF-8 LC_CTYPE inside Rscript and source app/helper files explicitly as UTF-8 |
| Empty Analytics shows stale chart | Table was cleared but chart stayed bound to nonempty history | Unbind/clear chart on empty, rebind on recovery; empty samples remain gaps |
| Monitor Enter does nothing | No datatable.row_activated handler despite the UI promise | Wire the documented event to task details |
| Monitor details omit result | selected_row() supplies an index, and the original dialog showed str(index) | row_data(index), locate the retained task and show its actual result/error |
| Different launch/test code paths | Default bootstrap used pkgload; old automation forced TERMR_USE_INSTALLED=1 | One current installed library with source/payload/R-platform fingerprints; reject stale/global fallback |
| Alt key delivery varies in native ConPTY | Some real native runs did not deliver Alt+S after F2, while WSL did | Visible F11/F12 alternatives; retain Alt aliases; no core input rewrite |
| Error-hook cleanup/exit semantics | Unhandled global error hooks can run before on.exit/finally-only unwinding; a returning diagnostic hook produced exit0 | Catch the condition at the app boundary, clean up, then rethrow; diagnostic hook preserves exit1 |

`failing-first-verified.log` has six failed expectations and exit1 before the
application fixes. Visual review later caught corrupt Windows Unicode labels
missed by numeric/DOM-only assertions. `unicode-before` is an additional real
browser failing-first run (exit1). Corrected proof now requires literal Tokyo
characters in both browser and native terminal output. The first draft test also contained an invalid processx env
vector; that harness error was corrected before the verified failing-first run.
The latest app suite has115 passing expectations per OS. No core defect was
confirmed or patched; all core/H1/H2/H3 hashes match the E-FIX starting snapshot.
