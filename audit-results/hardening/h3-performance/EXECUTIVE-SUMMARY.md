# H3 performance and memory

Four focused internal changes address measured costs: unused inkr reset during
unmount, repeated construction of inkr ancestor elements/keys, quadratic event
queue list copying, and chart publication starvation under a sustained backlog.
There is no new renderer, stylesheet engine, event loop, mandatory dependency,
native code, version change, commit, push or release.

| Scenario | Size | Before: median [min,max]; allocations | After: median [min,max]; allocations |
|---|---:|---|---|
| unmount-no-sheet | 1,000 | 1.020 s [1.000, 1.120]; 45.8886 MB; n=3 | 0.690 s [0.650, 0.750]; 12.9275 MB; n=3 |
| render-repeated | 10,000 | 5.250 s [5.110, 8.630]; 6.8411 MB; n=3 | 4.820 s [4.800, 4.890]; 6.8411 MB; n=3 |
| render-unique | 10,000 | 23.840 s [21.740, 31.560]; 360.9765 MB; n=3 | 19.860 s [19.490, 20.040]; 360.9765 MB; n=3 |
| deep-cold | 100 | 5.020 s [4.770, 5.050]; 6.1620 MB; n=3 | 1.360 s [1.220, 1.380]; 5.3471 MB; n=3 |
| micro-element | 1,000 | 0.470 s [0.450, 0.470]; 0.0000 MB; n=3 | 0.030 s [0.030, 0.040]; 0.0000 MB; n=3 |
| micro-hit | 1,000 | 0.140 s [0.140, 0.150]; 0.0000 MB; n=3 | 0.090 s [0.080, 0.100]; 0.0000 MB; n=3 |
| events-enqueue | 10,000 | 2.870 s [2.860, 3.050]; 820.9202 MB; n=3 | 0.220 s [0.220, 0.260]; 1.2016 MB; n=3 |
| events-dequeue | 10,000 | 1.260 s [1.240, 1.260]; 534.1790 MB; n=3 | 0.110 s [0.090, 0.150]; 0.0003 MB; n=3 |

Windows: TOTAL: 17090 tests, 0 failed, 0 errors, 94 skipped, 0 warnings. Status: OK.
WSL: TOTAL: 18618 tests, 0 failed, 0 errors, 30 skipped, 0 warnings. Status: OK.
Use TEST-RESULTS.md for exit codes and dependency exclusions, and
BENCHMARKS-BEFORE-AFTER.md for all repetitions and measurement limitations.

The final changes are four R files, three test files (one new), and two guides.
The two existing chart tests now require publication after the first bounded
chunk; all drain/order/capacity checks remain. H1/H2 source atomicity, export,
ownership, count validation, bubbling, Pilot cleanup and projection-key tests
remain in the regression run. Chart publication adds useful redraw work; it is
a freshness fix, not an allocation optimization.

Residual risks: sibling removal remains quadratic, global style epochs still
invalidate broadly, and public inkr session insertion still copies sibling keys
quadratically. Long-duration host/DB/network soak testing belongs to H4.

The alternating paired bridge experiment is the stronger inkr timing control:
four repetitions per variant in one R process, with the original bridge loaded
from the immutable snapshot. Element reuse and cache-hit work improve; the
unchanged public compute control is stable. Cold 1,000-wide unique render
ranges overlap, so a material wide-render speedup is not established. Do not
attribute the larger unpaired core timing differences entirely to this patch.
