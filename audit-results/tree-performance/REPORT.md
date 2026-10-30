# Tree construction scalability (pure R) — results

Environment: Windows 11, R 4.6.1, 20 logical cores, shared dev machine, timings are medians of 2-3 runs (`system.time`, 10 ms resolution).
Tree: `app(vertical(N x horizontal(label, input, button)))`, widgets = 4N+1. Raw data: `logs/build-*.csv`, scripts in this directory.

## 1. Where the time goes (measured)

| Finding | Evidence |
|---|---|
| Construction is **linear**, ~1.05-1.45 ms per widget; no quadratic term | build time per widget: 0.69 ms (101) ... 1.47 ms (3001), 3001/1001 = 3.1x for 3.0x widgets (`build-baseline.csv`); flat vertical of N labels also linear (`ctor-cost.R`) |
| Assembling the container and `app()` is negligible | 750 rows: widgets 4.05 s, `vertical()` 0.07 s, `app()` 0.09 s (`cpu-split.R`) |
| GC is not the problem | 0.2-0.7 s of 3-4 s; building with 5 big trees alive gives the same per-build time (`heap-effect.R`) |
| Per-widget cost = R6 instantiation + style parsing | `Widget$new()` 0.2-0.35 ms (54 public + 10 active + 9 private members cloned per instance; 80 members for a Label, 127 for an Input); default style 0.18-0.29 ms of which `parse_size` 70-80 us per string; `Rprof` share of `parse_size`/`tolower`/`trimws`/`sub`: 20-25% of a widget constructor |
| Input/Button heavier than Label | 0.9-1.5 ms vs 0.5 ms (more members, `merge_styles` for button variants, validation) |
| After construction, the first layout is cold | first `layout_tree` on 3001 fresh widgets 1.91 s vs 0.36 s warm: filling `computed_style` and natural-size caches (`first-layout.txt`: `natural_height` 76%, `computed_style` 37%, text measurement `render_lines` 23%) |
| Headless `test_app` start adds the R-level emulator | at 3001 widgets: build 3.3 s, start 5.7 s of which layout 34%, `VirtualTerminal$print_char` 27% |

No repeated tree walks or hidden quadratic behaviour were found in construction. `check_unique_ids_batch` (11% of an `app()` profile at 3001 widgets,
but `app()` is only 0.09 s) is linear.

## 2. Optimizations

| # | Change | Verdict |
|---|---|---|
| 1 | Bounded memo (512 entries) for `parse_size()` on strings (`R/style.R`: `size_cache`, `parse_size_string`). Pure function; errors are never cached; empty/NA strings bypass the cache. Public API unchanged. | **Kept**: 75 us -> 4.5 us per call, default style 183 -> 45 us, tree build -25..-27% |
| 2 | `sanitize_text()` fast path for printable ASCII (skip two regex passes) | **Reverted**: no measurable full-tree gain (3.21 -> 3.19 s, noise). The characterization test stays. |
| - | R6 instantiation (`lock_objects`, portable=FALSE, fewer methods) | **Not attempted**: would change class semantics/memory; not a minimal change |

Correctness evidence for #1: new test `parse_size results are stable under repeated and cached parsing` (compares against an inline reference
implementation over 14 inputs x 3 rounds, checks callers cannot corrupt the cache by modifying a returned spec, invalid inputs still error on
repeat including `""` and `NA_character_`, cache saturation after 2000 distinct strings). **The test caught a bug in my first version**
(`""` as environment key -> "zero-length variable name"), fixed by bypassing the cache for empty/NA strings.
Full suite after the change: 8613 tests, 0 failures, 0 warnings (18 skips: DBI absent, POSIX-only). Reactive fuzz (200 seeds), render
differential fuzz (40 seeds x 40 ops) and layout properties (100 trees): 0 violations.

## 3. Before / after (build time, memory)

| Widgets | Build before (s) | Build after (s) | Change | `lobstr::obj_size` before -> after (MB) | Peak "max used" before -> after (MB) |
|---|---|---|---|---|---|
| 101 | 0.07 | 0.06-0.07 | ~ | 6.2 -> 6.2 | 104.7 -> 104.7 |
| 301 | 0.44 | 0.31-0.33 | -25..-30% | 11.6 -> 11.4 | 105.5 -> 105.5 |
| 501 | 0.72 | 0.53-0.55 | -24..-26% | 16.9 -> 16.7 | 127.5 -> 147.9 (*) |
| 1001 | 1.42 | 1.06-1.11 | -22..-25% | 30.3 -> 29.8 | 165.2 -> 184.4 (*) |
| 2001 | 2.80 | 2.02-2.23 | -20..-28% | 57.1 -> 56.1 | 218.5 -> 279.0 (*) |
| 3001 | 4.40 | 3.19-3.21 | -27% | 83.8 -> 82.4 | 420.0 -> 436.5 (*) |

(*) Peak includes garbage from earlier benchmark iterations in the same process (the probe does not isolate runs); retained size
(`obj_size`) is the reliable memory figure: slightly smaller after (-1..-2%) because shared spec objects replace per-widget copies.
Memory per widget is ~27 KB retained either way. Two columns for "after" are the memo-only run and the memo + (later reverted) sanitize run;
the second differs only by noise.

Start-up of a headless app (`test_app` first render) is unchanged within noise (5.69 -> 5.4-6.1 s at 3001 widgets): it is dominated by cold
layout caches and the R-level virtual terminal.

## 4. What determines termr's scalability

1. **Widget count x R6 instance size.** Every widget is an R6 object with ~80-130 members, built by cloning function environments: ~0.3-0.6 ms and
   ~27 KB each. Tree construction is linear in widgets and cannot be reduced much without changing the object model.
2. **Style resolution and measurement caches** make the first layout ~5x more expensive than later ones (1.9 s vs 0.36 s at 3001 widgets); later
   operations are cheap because of the caches.
3. **Per-interaction cost** is set by whether a layout pass runs (O(widgets), ~0.1 ms/widget) and by painted area, not by tree construction; input edits no
   longer trigger layout when provably unneeded (phase 3).
4. In real use apps rarely hold 3000 widgets at once; virtualised widgets (`data_table`, `log_view`, `tree_view`) avoid per-row widgets and are the
   scalable choice for large data.

## 5. Not done / limits
- No `profvis` flame graph (Rprof used; on Windows its 5-10 ms sampling undercounts total time, shares are reliable, absolute sampled seconds are not).
- Not measured on WSL/Linux; no comparison with v1.0.1; no R CMD check re-run in this task (suite and fuzzers re-run).
- Changed files in this task: `R/style.R`, `tests/testthat/test-style.R`, `tests/testthat/test-unicode.R` (test only). Nothing committed.
