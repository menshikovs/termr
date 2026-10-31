# Widget lifecycle

| Scenario | Size | Before: median [min,max]; allocations | After: median [min,max]; allocations |
|---|---:|---|---|
| unmount-no-sheet | 100 | 0.010 s [0.000, 0.020]; 3.5273 MB; n=3 | 0.020 s [0.020, 0.020]; 0.3526 MB; n=3 |
| unmount-no-sheet | 1,000 | 1.020 s [1.000, 1.120]; 45.8886 MB; n=3 | 0.690 s [0.650, 0.750]; 12.9275 MB; n=3 |
| unmount-no-sheet | 5,000 | 26.120 s [25.030, 26.330]; 467.2806 MB; n=3 | 18.050 s [17.820, 18.750]; 301.9355 MB; n=3 |

App widget_unmounting and screen_leaving skip bridge cleanup/reset when no
inkr stylesheet exists. Clearing a stylesheet already clears all bridge state.
When a sheet exists the original cleanup and invalidation remain. Disposal,
timer cancellation, worker ownership, focus/hover/capture cleanup, lifecycle
events and parent mutation order are unchanged. Startup/shutdown and large
subtree mount are included in broad/extra scenarios; the full suite covers
custom remove hooks, DBI ownership (WSL), reactive disposal and detached bubbling.

The vapply(identity) search and parent list reconstruction in Widget detach
remain O(n²) across remove_children. Removing or reordering those operations
would change observations made by custom remove/dispose callbacks. This stage
removes the proven redundant allocation without silently changing callback
ordering. At 5,000 siblings the residual cost is significant and is a concrete
H4/H-next optimization candidate requiring a dedicated lifecycle contract.

The 1,000-cycle create/mount/stream/unbind/close workload checks subscriber
count and running state on every cycle; MEMORY.md records GC-visible live
objects and open R connections. These assertions complement, rather than
replace, longer resource-lifecycle tests.
