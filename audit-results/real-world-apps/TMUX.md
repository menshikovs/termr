# Phase E — Tmux

`tmux-e2e.py` creates a fresh `tmux -L termr-phase-e-<uuid>` server namespace,
then runs real showcase, distributed monitor and fixture rtop applications.
It waits for startup, sends actual keys, resizes to42x18 and back to100x30,
captures pane text and quits normally. Shell-side before/after terminal-mode
comparison must write PASS. A finally block kills only that fresh namespace.

Final three cases PASS with cleanup=true in `final-wsl/tmux/results.json`;
pane captures and owned-session marker files are alongside it. Ubuntu tmux 3.6
was actually run. Windows tmux 3.6a-win32 was discovered but not used as a
substitute for native attached-console validation. No unrelated user session
or server was stopped.

Run `Rscript tools/integration/run-all.R --mode=tmux --timeout=180` in WSL.
The captures complement semantic app and pexpect assertions: a pane image alone
does not establish safe data edits or worker cleanup. No claim is made about
screen, arbitrary SSH clients or other terminal emulators.
