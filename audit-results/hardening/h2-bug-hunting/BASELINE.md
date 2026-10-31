# Baseline Verification & Environment

**Date**: 2026-10-31  
**Working Branch**: `2.0-termr`  
**Base Commit**: `9825b42` (termr 2.0 development tree)  

---

## 1. Environment Specifications

### Windows Host
- **Operating System**: Windows 11 Pro 64-bit (10.0.26100)
- **R Version**: R 4.6.1 ucrt (2025-10-31)
- **R Binaries**: `C:\Program Files\R\R-4.6.1\bin\x64\Rscript.exe`
- **Shell**: PowerShell 7 / Windows Terminal
- **Console VT**: Windows VT console enabled (`ENABLE_VIRTUAL_TERMINAL_PROCESSING`)

### WSL Subsystem
- **Distribution**: Ubuntu 26.04.1 LTS (Linux kernel 6.6.x x86_64)
- **R Version**: R 4.5.2 (2025-10-31)
- **Dependencies Installed**: `testthat` (3.2.3), `R6` (2.6.1), `DBI` (1.2.3), `RSQLite` (2.3.9), `vctrs` (0.6.5), `blob` (1.2.4), `haven` (2.5.4), `units` (0.8-5), `sf` (1.0-19), `bit64` (4.5.2).
- **Optional Dependencies Absent**: `inkr`, `mirai`, `nanonext` (kept optional per project rules).
- **Python Version**: Python 3.14.4 (with standard `pty`, `termios`, `fcntl` libraries).

---

## 2. Git Baseline State

Prior to H2 remediation, `git status --short` contained:
- Modified files from previous phases (`R/app.R`, `R/widget-datatable.R`, `R/sql.R`, `R/database-explorer.R`, `R/style.R`, `R/widget.R`, `DESCRIPTION`, `NAMESPACE`).
- Untracked benchmark, docs, and audit directories from earlier audits.
- No unstaged destructive modifications.

Baseline hash verification:
- All core source files matched their H1 baseline hashes prior to H2 surgical patches.
- No generated `man/` or `NAMESPACE` files were edited by hand.\n