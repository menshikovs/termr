#!/bin/sh
set -eu
gdb --batch -p "$1" -ex 'set pagination off' -ex 'thread apply all bt 12'
