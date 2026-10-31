# Event queue and input latency

| Scenario | Size | Before: median [min,max]; allocations | After: median [min,max]; allocations |
|---|---:|---|---|
| events-enqueue | 1 | 0.000 s [0.000, 0.000]; 0.0000 MB; n=3 | 0.000 s [0.000, 0.000]; 0.0000 MB; n=3 |
| events-dequeue | 1 | 0.000 s [0.000, 0.000]; 0.0000 MB; n=3 | 0.000 s [0.000, 0.000]; 0.0000 MB; n=3 |
| events-enqueue | 100 | 0.010 s [0.000, 0.020]; 0.0875 MB; n=3 | 0.000 s [0.000, 0.000]; 0.0068 MB; n=3 |
| events-dequeue | 100 | 0.000 s [0.000, 0.000]; 0.0684 MB; n=3 | 0.000 s [0.000, 0.000]; 0.0003 MB; n=3 |
| events-enqueue | 10,000 | 2.870 s [2.860, 3.050]; 820.9202 MB; n=3 | 0.220 s [0.220, 0.260]; 1.2016 MB; n=3 |
| events-dequeue | 10,000 | 1.260 s [1.240, 1.260]; 534.1790 MB; n=3 | 0.110 s [0.090, 0.150]; 0.0003 MB; n=3 |

The event loop is unchanged. Only EventQueue's private storage changes from
a copy-on-modify list to an instance-owned hash environment with reusable FIFO
ring slots. Capacity starts at 64, doubles on demand, and shrinks when drained.
Popped bindings are removed immediately. Draining a large burst replaces its
expanded hash table; small queues reuse their storage. clear() releases all
bindings. NULL push remains a no-op. Ring indices stay within capacity and
size() remains integer. Slot names are bounded by peak queue depth, avoiding
both lifetime index overflow and an unbounded stream of interned R symbols.
The queue is not newly bounded: App's existing per-tick budget is retained.

Regression tests check allocation growth, 1,100-item interleaved FIFO, empty/
clear/reuse, independent instances, wrapped growth and 10,000 sustained
non-empty operations with bounded slot indices.
The budget is 2 MB for 1,000 prebuilt events, comfortably above observed new
allocations and below the original 8.29 MB quadratic copies. There is no
wall-clock test threshold. Timer/input/worker suites and PTY Tab+Enter validate
dispatch order and reentrant behavior at the App level.

Extra rows separate direct dispatch including a handler from enqueue-through-
next-headless-frame for 1/100/10,000 events. Event construction and setup are
excluded from these operations. Other rows measure idle, focus, widget update
and resize. Do not read these as OS keyboard-to-photon latency. The parser and
real POSIX PTY remain separate validation layers; Windows live-console timing
was not available.

Growth reindexes only pending items when capacity doubles, so push is amortized
O(1), pop O(1), and a growth step O(pending). An empty large queue releases its
expanded storage. R may retain interned slot symbols up to the largest historic
capacity; their range depends on peak pending depth, not lifetime throughput.
The rejected monotonically numbered candidate and its lifetime measurements
are documented in MEMORY.md. Original list-copy measurements remain the H2
baseline; final ring measurements replace the intermediate environment numbers.

Granular CSVs also measure 100 actual Tab transitions through an App with 1,000
focusable buttons and parser feeds containing 1/100/10,000 combined Tab+Enter
pairs. Parser rows count pairs (two events each); they exclude OS reads and App
dispatch. The earlier tree-focus row has non-focusable labels and measures the
empty-chain scan, not the same workload as real button focus traversal.
