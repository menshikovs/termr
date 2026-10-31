#!/usr/bin/env bash
set -u
cd /mnt/c/programming_pj/r_textualize || exit 2
out=audit-results/hardening/h1-architecture
mkdir -p /tmp/termr-h1-lib
export R_LIBS_USER=/tmp/termr-h1-lib:/home/user001/R/x86_64-pc-linux-gnu-library/4.5
export LANG=C.UTF-8 LC_ALL=C.UTF-8 NOT_CRAN=true TERM=xterm-256color
R CMD INSTALL -l /tmp/termr-h1-lib /mnt/c/programming_pj/ink-for-r > "$out/install-inkr-wsl.log" 2>&1 || exit 3
R CMD INSTALL -l /tmp/termr-h1-lib /mnt/c/Users/User001/AppData/Local/Temp/termr-inkr-rcheck-windows-final/termr_1.0.1.tar.gz > "$out/install-baseline-wsl.log" 2>&1 || exit 4
Rscript audit-results/hardening/h1-architecture/inventory.R > "$out/inventory-wsl.log" 2>&1
echo $? > "$out/inventory-wsl.exit"
Rscript audit-results/hardening/h1-architecture/probe-contracts.R > "$out/probes-wsl-before.log" 2>&1
echo $? > "$out/probes-wsl-before.exit"
Rscript tools/pty/test-fixture.R > "$out/pty-fixture-wsl-before.log" 2>&1
echo $? > "$out/pty-fixture-wsl-before.exit"
python3 tools/pty/pty-check.py --case combined_focus_session > "$out/pty-combined-wsl-before.log" 2>&1
echo $? > "$out/pty-combined-wsl-before.exit"
cat "$out/probes-wsl-before.log"
cat "$out/pty-combined-wsl-before.log"
