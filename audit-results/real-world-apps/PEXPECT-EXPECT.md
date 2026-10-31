# Phase E — Pexpect Expect

`integration-apps/automation/pty-e2e.py` uses real POSIX pexpect terminals with
the installed candidate, UTF-8, 100x30 initial size and bounded semantic waits.
It drains output continuously (preventing a full PTY buffer from starving R),
and waits for observable state around Escape rather than relying on long sleeps.
It exercises arrows, Tab/Shift+Tab/Enter/Escape, fragmented CSI input, Unicode
search, dataset/source/theme/A4/chart selection, live tasks and reconnects.

Final `final-wsl/pty/results.json`: showcase, analytics, monitor and rtop PASS,
normal exit 0 and restored `stty -g`. `pty-baseline/results.json` separately
certifies the genuine baseline rtop path. `pty-crash/results.json` verifies
controlled Ctrl+E callback failure (expected exit 1) restores the terminal;
`pty-interrupt/results.json` verifies normal Ctrl+C exit 0/restoration after
focusing the chart (DataTable intentionally reserves Ctrl+C for copy).

Independent Tcl Expect 5.45.4 smoke tests run showcase and monitor with keyboard
input and restoration checks; a controlled timeout fixture is cleaned up using
only its owned PID. Final logs are under `final-wsl/expect/`, with both exit 0
in the runner summary. The pexpect module is4.9.0, Python 3.14.4.

The initial PTY harness failed because it did not drain output and assumed
Escape reached App while a cell editor consumed it. Those harness/oracle issues
were fixed; they were not termr rendering defects. Failure cleanup targets only
the newly spawned process group, first interrupt then bounded force-stop.
These Linux PTY results do not certify native Windows Console, SSH or RStudio.
