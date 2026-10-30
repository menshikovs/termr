# 05 Suspected / unconfirmed

- S-1: `check_count()` returns `NA` with a warning for values beyond integer range. Only `layout_diagnostics` was hardened; other
  callers of the shared helper were not audited for NA propagation.
- S-2: `Pilot$wait_until_exit(timeout, interval)` with a pathologically small `interval` (1e-12) iterates about timeout/interval
  times (1e-7 took 5 s for a 0.01 s timeout). Contrived; unchanged.
- S-3: SIGTERM and SIGHUP delivered to a running termr process leave the terminal in raw mode on the alternate screen with the cursor
  hidden (SIGINT is restored). R code cannot trap SIGTERM, so this is probably inherent. It is not documented in `docs/terminal.md`
  or `docs/ssh.md`; a note or a shell-wrapper recipe (trap TERM, then `stty sane` and the reset escapes) would help.
- S-4: Ctrl+D is ignored by apps (no EOF handling). Probably by design; undocumented.
- S-5: Flooding 3000 key bytes into a PTY at 80x24 took about 270 s to drain (about 90 ms/key) with an input + text_area UI;
  headless cost is 5 ms/key (input) and 25 ms/key (empty text_area). Dominated by a full layout pass per key (see 06). No hang,
  but held key repeat can lag on slow terminals.
- S-6: Known open issue from project memory (native crash 0xC0000005 in ConPTY, about 25% of runs on some earlier build): not observed
  in 7 of 7 ConPTY runs here; not investigated further.
