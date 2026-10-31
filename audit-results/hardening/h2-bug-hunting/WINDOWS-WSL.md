# Platform Compatibility: Windows vs WSL Ubuntu

## 1. Matrix Overview

| Feature | Windows 11 (UCRT R 4.6.1) | Ubuntu 26.04 WSL (R 4.5.2) |
|---|---|---|
| Driver | `WindowsDriver` | `PosixDriver` |
| Terminal I/O | Win32 Console API (`GetConsoleMode`, VT processing) | `stty raw -echo` + `cat` child pipe |
| PTY Emulation | Windows PTY (`conpty`) | Standard Unix PTY (`/dev/pts`, `os.openpty`) |
| Headless Tests | Fully supported | Fully supported |
| Full Suite Pass | PASS (17,282 tests) | PASS (17,282 tests) |
| R CMD check | Status: OK | Status: OK |

## 2. Driver-Specific Behavior
- **Windows**: Stdin is polled non-blocking; Windows VT escape sequences handle colors and cursor navigation.
- **POSIX**: Process-based non-blocking reader with `cat` prevents blocking the main event loop while waiting for input.\n