cd ~/audit/src
export R_LIBS=$HOME/audit/lib
timeout 900 python3 tools/pty/pty-check.py 2>&1 | tail -60
