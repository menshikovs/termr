#!/usr/bin/env bash
set -u
cd /mnt/c/programming_pj/r_textualize || exit 2
out=audit-results/real-world-apps
export LC_ALL=C.UTF-8 LANG=C.UTF-8
for tool in R Rscript python3 pip3 hyperfine tmux expect asciinema cmake gcc curl apt-get dpkg-deb; do
  printf '%s: ' "$tool"
  command -v "$tool" || true
done
python3 -c 'import sys,importlib.util; print(sys.version); print("pexpect",importlib.util.find_spec("pexpect")); print("venv",importlib.util.find_spec("venv"))'
Rscript "$out/inventory.R"
