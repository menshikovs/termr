# Performance (Windows 11, R 4.6.1, 20 logical cores, headless pilot 120x40; date 2026-10-29)

Tree: `vertical` of N rows, each `horizontal(label, input, button)` (widgets = 4N+1). `system.time` resolution on Windows is 10 ms.
Raw data: `logs/bench-baseline.csv`, `logs/bench-after-opt.csv`, `logs/phases-after.csv`. Commands: see reproduction.md.

## Keypress latency in a focused input (median ms of 12-30 keys)
| widgets | before (full layout per key) | after (layout skipped) | speed-up |
|---|---|---|---|
| 133 | 40 | 5 | 8x |
| 401 | 100 | 10-15 | 7-10x |
| 665 | 130 | 10 | 13x |
| 1333 | 235 | 15 | 15x |
| 2001 | 360 | 20 | 18x |
| 3001 (after only) | - | 50 | - |

(The two CSV files hold the exact medians/min/max; the table rounds them. Differences below 10 ms are within timer resolution.)

## Phase breakdown after the change (ms)
| widgets | create tree | layout | full paint | snapshot | key (input) |
|---|---|---|---|---|---|
| 301 | 410 | 40 | 70 | 10 | 20 |
| 1001 | 820 | 70 | 40 | 20 | 20 |
| 1501 | 1490 | 200 | 100 | 50 | 30 |
| 3001 | 4230 | 390 | 110 | 100 | 50 |

- Tree creation is the dominant remaining cost (about 1.4 ms/widget, super-linear above ~1500). Not profiled to function level in this phase.
- `layouts_per_key` is 0.04-0.09: the one layout counted per run is the focus/first-key pass, none per typed key.
- Not optimised: focus changes (`tab`) still lay out; in the headless pilot most of their cost is the R-level VirtualTerminal.
- Memory: see memory.md. Environment is a shared dev machine; runs were not isolated from other processes, and the 100k-event run
  overlapped with another R job, so absolute timings (9.4 ms/event at 100k) are inflated versus the 4.5 ms/event of the 1k run.
