#!/bin/sh
set -eu
cd /mnt/c/programming_pj/r_textualize
export R_LIBS=/mnt/c/programming_pj/r_textualize/audit-results/shiny-plotly/lib-wsl:/mnt/c/programming_pj/r_textualize/audit-results/nanonext/lib-wsl
export R_TESTS=
python3 tools/pty/pty-check.py
