#!/bin/sh
set -eu
gdb --batch -p "$1" -ex 'set pagination off' -ex 'thread 1' -ex 'bt 70' -ex 'frame 10' -ex 'info locals' -ex 'p sock->s_refcnt' -ex 'p sock->s_sock_ops'
