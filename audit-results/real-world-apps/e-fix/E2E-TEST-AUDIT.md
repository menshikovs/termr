# E-FIX — E2E Test Audit

Previous Phase E reports were excluded from gate decisions. Reused scripts were
read, repaired where necessary and executed again into e-fix/ directories.

The earlier tests did use real renderers/workers, but had material blind spots:
default startup loaded source through pkgload while automation selected an old
isolated installed build; no fingerprint tied that installation to the checkout.
This was a provenance gap, not proof that stale package code caused the user's
particular startup symptom. A diagnostic R_PROFILE_USER records paths and errors;
it does not source a different app. Manual launcher execution also used the
ordinary profile path. Numeric/DOM browser assertions originally missed corrupt
Unicode labels; final assertions require the literal Unicode label as well.
Many tests called application constructors rather than the CLI. Chart assertions
often checked only screen height; theme/source flags could not prove displayed
data. No test pressed Enter and asserted real task result text, nor asserted that
empty cleared the chart. App-level error-to-notification handlers can keep a
process alive despite a failed action, so exit0 alone is inadequate.
The integration-apps directory and its tests are excluded from the package
tarball. An ordinary R CMD check therefore does not execute these applications
at all; it must never substitute for their separate startup/interaction gates.

Current layers:

1. Installed export/formal/method audit and recorded real return classes.
2. Missing/stale/tampered-build negative controls and cwd startup regression.
3. Real headless renders, data/order/edit assertions and five distinct numeric
   chart bodies, not just nonempty title/screen dimensions.
4. Actual documented entrypoint under native ConPTY and POSIX PTYs, bounded
   first-frame/state waits, stderr and exit validation.
5. Real keyboard operations with screen changes and semantic events.
6. Invalid edits, empty/recovery, failed/cancelled tasks and controlled crash.
7. Pool/transport/source/subscription cleanup and independent observed PID checks.

The new diagnostic error hook initially exposed two harness pitfalls: quit() can
bypass unprotected owner unwinding, while returning from options(error=...) can
make Rscript exit0. The app now catches/cleans/rethrows before the hook; the hook
captures traceback and preserves exit1. Failed exploratory logs remain retained.

WSL DrvFS sometimes returned ENODATA(61) while reading an actively appended JSONL
journal. A traceback located the failure in Python file.read, not the application
or recorder. event_log.py retries only EAGAIN/ENODATA/ESTALE reads, at most5 times
with10ms gaps, logs retries, and raises persistent errors. It never repeats app
actions or whole scenarios. This corrects an observability race rather than
silently converting application failures into passes.

Unified command: `Rscript tools/integration/run-all.R --mode=api,gates,unit,process`.
Windows gates include Chrome. Linux terminal gates run directly; the runner
explicitly tells users to invoke the separately verified Windows browser bridge
for WSL Shiny rather than falsely claiming a Linux browser-engine test.
