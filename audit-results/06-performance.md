# 06 Performance (Windows R 4.6.1, headless pilot at 120x40; startup measured in WSL)

Single machine with other jobs sometimes running: compare shapes, not absolute values.

| widgets (rows x 3) | create ms | keypress in Input ms | forced full repaint ms |
|---|---|---|---|
| 30 | 30 | 10 | 60 |
| 150 | 230 | 50 | 100 |
| 600 | 1080 | 140 | 200 |
| 1500 | 2800 | 350 | 420 |

- Keypress latency is O(widgets). `Rprof` of 30 keypresses at 600 widgets: 97% in `refresh_screen`, 67% in `layout_tree`
  (`Input` edits call `invalidate()`, which relays out the whole tree because the text width may change). Not a defect. A possible
  optimisation is `invalidate_paint()` when the natural width does not change; it needs care.
- 2000 keypresses on 60 widgets: 54 s (27 ms/key), memory delta 0.0 MB. 300 mount/remove cycles: +0.2 MB. No leaks seen.
- Startup (WSL, hyperfine, 10 runs): bare `Rscript -e 1` 92.6 ms; `library(termr)` 101.5 ms, so package load is about 9 ms.
- Regression comparison against the previous version: not done (no baseline benchmark run).
- Resize timings from my script (about 1 s) were dominated by Pilot idle waits and are not meaningful.
