#!/usr/bin/env python3
"""Real-PTY smoke test for raw-byte table rendering on POSIX hosts."""
import importlib.util
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
CHECK_PATH = os.path.join(HERE, "pty-check.py")
APP_PATH = os.path.join(HERE, "binary-app.R")

spec = importlib.util.spec_from_file_location("termr_pty_check", CHECK_PATH)
pty_check = importlib.util.module_from_spec(spec)
spec.loader.exec_module(pty_check)

os.chdir(ROOT)
os.environ.setdefault("LANG", "C.UTF-8")
os.environ.setdefault("LC_ALL", "C.UTF-8")

session = pty_check.Session(APP_PATH, cols=72, rows=16)
try:
    session.wait_for("1 byte: 1B", 60)
    session.wait_for("1 byte: C3", 10)
    visible = pty_check.strip(session.output)
    controls = [ord(char) for char in visible
                if ord(char) < 32 and char not in "\n\r\t"]
    pty_check.check("raw ESC/NUL/FF/invalid UTF-8 render as hex",
                    all(marker in visible for marker in
                        ("1 byte: 1B", "1 byte: 00", "1 byte: FF", "1 byte: C3")),
                    repr(visible[-400:]))
    pty_check.check("Unicode column label reaches the PTY", "payload_µ" in visible,
                    repr(visible[-400:]))
    pty_check.check("binary output contains no terminal control bytes",
                    not controls and "\x1b" not in visible and "\ufffd" not in visible,
                    f"control code points={controls!r}; tail={visible[-400:]!r}")
    session.send("q")
    pty_check.check("binary PTY app exits normally", session.wait_exit() == 0,
                    f"status={session.status}; tail={visible[-200:]!r}")
finally:
    pty_check.close_sessions("binary PTY check")

if pty_check.check.failed:
    sys.exit(1)
print("all binary PTY checks passed")
