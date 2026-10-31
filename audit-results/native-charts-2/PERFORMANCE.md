# Performance

## Method

Measured on Windows 11 with R 4.6.1 and an 80×24 headless viewport (resize alternated with 100×30). The current worktree and feature baseline were loaded in separate fresh R processes using the same `tools/bench/bench-native-charts.R` harness and deterministic inputs. The baseline source was extracted from feature commit `a3d6178647569dc586371c02ea5316041810a5d6`; it was not checked out or modified.

Values are elapsed milliseconds. Build uses 20 constructor repetitions per sample; update uses 50 replacements; selection and full repaint use 10 operations; ordinary render uses median of 7, app startup uses median of 5, grouped bars use median of 9, and heatmap uses median of 5 except 1000×1000, which uses one sample. `render_alloc_mb` is cumulative allocation counted by `Rprofmem()` during rendering, not peak resident memory. `headless_app_start_ms` includes test-app and virtual-driver setup. Timer granularity is approximately 10 ms, so a reported `0` means below timing resolution.

## Large line and scatter inputs

| Chart, points | Metric | Feature baseline | 2.0 integration |
| --- | --- | ---: | ---: |
| Line, 100,000 | Build | 7.0 | 7.0 |
|  | First render | 30 | 30 |
|  | Headless app start | 300 | 320 |
|  | `update_data()` | 6.4 | 5.8 |
|  | Selection repaint | 8 | 6 |
|  | Full repaint | 17 | 17 |
|  | Resize | 400 | 410 |
|  | Render allocations | 30.598 MB | 30.600 MB |
| Scatter, 100,000 | Build | 7.0 | 5.5 |
|  | First render | 30 | 40 |
|  | Headless app start | 310 | 330 |
|  | `update_data()` | 5.8 | 6.2 |
|  | Selection repaint | 6 | 5 |
|  | Full repaint | 17 | 17 |
|  | Resize | 395 | 390 |
|  | Render allocations | 28.985 MB | 28.987 MB |

Across the full 100/1,000/10,000/100,000 point matrix, build and update costs scaled similarly in both source trees. Small differences in individual render and app-start samples varied between runs; these measurements do not establish a speedup or a statistically significant regression. Rprofmem totals for the 100,000-point renders differed by about 2 KB.

## Heatmap and grouped bars

| Shape | Feature baseline | 2.0 integration | Input object size |
| --- | ---: | ---: | ---: |
| Heatmap 10×10 | 40 ms | 40 ms | 0.001 MB |
| Heatmap 100×100 | 100 ms | 90 ms | 0.076 MB |
| Heatmap 1000×1000 | 300 ms | 280 ms | 7.630 MB |
| Grouped bar, 1000 categories × 8 series | 140 ms | 140 ms | 0.062 MB |

The grouped-bar sample initially varied between 140 and 190 ms on the 2.0 worktree. Increasing repetitions from 3 to 9 produced a 140 ms median for both source trees.

## Stream dispatch and burst updates

On the current 2.0 integration, a mounted line chart enqueued 10,000 ordered events in 870 ms (0.087 ms per event) into a 10,000-record bounded queue without drops. This measures synchronous callback/queue work and does not include chart repaint.

A 100-event burst with `max_points = 600` drained in seven bounded 16-record-or-smaller passes. The first pass measured below the 10 ms timer resolution; the remaining passes plus the final repaint took 150 ms, and the complete drain measured 150 ms. Chart state is accumulated between passes and `update_data()` is called once after the queue drains. This stream protocol does not exist on the feature baseline, so no cross-branch stream comparison is claimed.

Earlier benchmark iterations repainted after every chunk and took approximately 870 ms for the same 100-event case. Deferring the update until drain completion reduced that cost by avoiding repeated chart normalization and full repaint while allowing the event loop to run between bounded chunks.

## Reproduction

```powershell
Rscript tools/bench/bench-native-charts.R . termr-2.0
Rscript tools/bench/bench-native-charts.R C:/path/to/feature-source feature-core-charts-1.1
```

The harness separates constructor, render, update, selection repaint, full repaint, resize, stream queueing, and drain work. Headless timings are not interactive terminal guarantees; run PTY and real-terminal checks on target hosts.
