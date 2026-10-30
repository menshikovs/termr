#!/usr/bin/env python3
"""Real Unix PTY check for the installed optional mirai task-monitor example."""
import importlib.util
import json
import os
from pathlib import Path
import tempfile
import time
import sys

sys.dont_write_bytecode = True

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("termr_pty", HERE / "pty-check.py")
harness = importlib.util.module_from_spec(spec)
spec.loader.exec_module(harness)


def mirai_session():
    with tempfile.TemporaryDirectory(prefix="termr-mirai-pty-") as directory:
        log = Path(directory) / "state.json"
        script = Path(directory) / "monitor.R"
        script.write_text('''
library(termr)
source(system.file("examples", "mirai-tasks", "tui.R", package="termr"))
demo <- task_monitor(2L, initial=0L)
# Test-only introspection identifies exact owned daemon processes even if the
# backend detached/reparented them. Applications use only the exported API.
profile <- attr(demo$model$pool, "termr_mirai", exact=TRUE)$profile
probes <- mirai::everywhere(Sys.getpid(), .min=2L, .compute=profile)
deadline <- proc.time()[["elapsed"]]+10
while(any(vapply(probes, mirai::unresolved, logical(1)))) {
  if(proc.time()[["elapsed"]]>deadline) stop("daemon PID probe timed out")
  Sys.sleep(.005)
}
pids <- vapply(probes, function(x) x$data, 0L)
stopifnot(length(unique(pids))==2L)
children <- lapply(pids, ps::ps_handle)
for(i in 1:4) demo$model$submit(chunks=400L)
demo$app$set_interval(.02, function(app) {
  x <- demo$model$pool$diagnostics()
  jsonlite::write_json(list(inputs=app$query_one("#inputs")$text,
    pending=x$pending, executing=unname(x$backend$mirai[["executing"]]),
    cancelled=x$counters$cancelled), Sys.getenv("TERMR_MIRAI_PTY_LOG"), auto_unbox=TRUE)
})
tryCatch(termr::run(demo$app), finally={
  demo$close()
  deadline <- proc.time()[["elapsed"]]+5
  while(any(vapply(children, ps::ps_is_running, logical(1))) && proc.time()[["elapsed"]]<deadline) Sys.sleep(.01)
  stopifnot(!any(vapply(children, ps::ps_is_running, logical(1))))
  cat("__MIRAI_CLEAN__\\n")
})
''', encoding="utf-8")
        session = harness.Session(str(script), cols=110, rows=18,
                                  extra_env={"TERMR_MIRAI_PTY_LOG": str(log)})
        before = session.attrs()
        session.wait_for("mirai task monitor", 30)

        def state():
            try:
                return json.loads(log.read_text())
            except (FileNotFoundError, json.JSONDecodeError):
                return {}

        harness.check("both mirai workers execute while TUI is active",
                      harness.wait_until(lambda: state().get("executing") == 2, session, 10), repr(state()))
        started = time.monotonic()
        session.send("iii")
        harness.check("real terminal input reaches UI during computation",
                      harness.wait_until(lambda: state().get("inputs") == "Input probe: 3", session, 3), repr(state()))
        print(f"PTY key-to-observed-state latency ms: {(time.monotonic()-started)*1000:.2f}")
        harness.check("background work remains pending", state().get("pending", 0) > 0, repr(state()))
        session.send("c")
        harness.check("own running task can be cancelled from keyboard",
                      harness.wait_until(lambda: state().get("cancelled", 0) >= 1, session, 5), repr(state()))
        session.resize(70, 14)
        session.send("i")
        harness.check("input remains responsive after resize",
                      harness.wait_until(lambda: state().get("inputs") == "Input probe: 4", session, 3), repr(state()))
        session.send("q")
        harness.check("task monitor exits normally", session.wait_exit(15) == 0, str(session.status))
        harness.check("all owned daemon children exited", "__MIRAI_CLEAN__" in session.output, session.output[-300:])
        harness.check("terminal attributes restored", session.attrs() == before, "termios differs")
        harness.teardown_modes(session)
        session.close()


if __name__ == "__main__":
    harness.require_current_install()
    harness.run_cases([mirai_session])
