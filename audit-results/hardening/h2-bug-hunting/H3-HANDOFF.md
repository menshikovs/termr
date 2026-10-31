# Phase H3 Handoff & Optimization Recommendations

With all correctness defects fixed, invariants hardened, and full test suites green, Phase H3 should prioritize optimization and profiling:

1. **Chart Streaming Allocation Optimization**:
   - Profile allocations in `chart_stream_queue_drain()` and reduce intermediate list allocations during sustained bursts.
2. **Incremental Diff Rendering**:
   - Profile ANSI escape generation for large data table scrolling to minimize byte output.
3. **Long-Running Soak Testing**:
   - Implement Phase H4 soak tests running continuous event loops over extended durations to verify zero memory drift.\n