# inkr bridge

| Scenario | Size | Before: median [min,max]; allocations | After: median [min,max]; allocations |
|---|---:|---|---|
| render-repeated | 10,000 | 5.250 s [5.110, 8.630]; 6.8411 MB; n=3 | 4.820 s [4.800, 4.890]; 6.8411 MB; n=3 |
| render-unique | 10,000 | 23.840 s [21.740, 31.560]; 360.9765 MB; n=3 | 19.860 s [19.490, 20.040]; 360.9765 MB; n=3 |
| deep-cold | 100 | 5.020 s [4.770, 5.050]; 6.1620 MB; n=3 | 1.360 s [1.220, 1.380]; 5.3471 MB; n=3 |
| micro-element | 1,000 | 0.470 s [0.450, 0.470]; 0.0000 MB; n=3 | 0.030 s [0.030, 0.040]; 0.0000 MB; n=3 |
| micro-hit | 1,000 | 0.140 s [0.140, 0.150]; 0.0000 MB; n=3 | 0.090 s [0.080, 0.100]; 0.0000 MB; n=3 |

The bridge still calls only public inkr exports. inkr itself is unchanged.
inkr_element_for_widget now recursively reuses parent representations through
the existing widget epoch cache. inkr_path_key_for_widget memoizes the same
validated control-delimited path representation, using a cached parent prefix.
The sheet generation remains part of the App cache key. Cache hits avoid
ancestor-list construction; misses still use the original cascade, explicit
ancestor flags and eight-property adapter.

State overrides are part of the widget-local cache entry. Ancestor class/state,
focus, disabled, tree mutation and stylesheet replacement continue to use the
existing epoch invalidation. Clear/unmount explicitly remove the new entries.
Entries contain inkr values/strings, not references to widgets or Apps. The
existing per-App FIFO remains limited to 4,096 styles; there is no global cache
or TTL. The tradeoff is two additional lazy cache entries per visited widget,
and path-prefix strings still grow with depth. Global invalidation is retained.

Core CSVs cover 100/1,000/10,000 repeated and unique identities, 100 nested
containers, element creation, parent paths, cache hits and public ink_compute.
Component CSVs separately measure ink_match, adapter mapping, insertion,
invalidation, class changes and stylesheet swaps. Existing integration tests
cover cascade, inheritance, precedence, focus, disabled and atomic replacement;
H3 adds construction-count, override and reparenting tests.

Public ink_session_set insertion is measured unchanged at 100/1,000/2,000
siblings: allocations are approximately 0.047/4.098/16.185 MB. Doubling the
last size almost quadruples bytes. The independent inkr source still appends
sibling keys with c(existing, key); see R/session-state.R in the sibling repo.
The stateless bridge is retained rather than switching to this session path.
The minimal independent reproducer is the inkr-session-insert block in the
frozen benchmark; it uses only public functions and can run in inkr's repository.

## Alternating paired control

| Paired bridge operation | Before median [min,max], seconds | After median [min,max], seconds |
|---|---:|---:|
| render-unique-1000 | 3.225 [2.290, 4.350] | 3.160 [3.030, 3.380] |
| element-1000 | 0.590 [0.570, 0.600] | 0.030 [0.030, 0.050] |
| cache-hit-1000 | 0.175 [0.170, 0.180] | 0.110 [0.090, 0.110] |
| deep-element-100 | 6.385 [6.200, 6.420] | 0.105 [0.090, 0.110] |
| compute-control-1000 | 0.690 [0.690, 0.690] | 0.700 [0.690, 0.750] |

This series alternates before/after and after/before order, after warming both,
with four recorded repetitions per variant. It compares the actual baseline
bridge functions with current ones, not a rewritten model. Setup is excluded.
Whole cold wide render is effectively unchanged within spread; the clear gains
are repeated public element requests, deep ancestor reuse and bridge cache
hits. The unchanged ink_compute control helps detect unrelated machine drift.
The main core series remains useful for allocations and coverage, with its
larger timing limitations explicitly retained.
