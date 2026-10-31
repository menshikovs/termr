# Performance & Safety Verification

## 1. Frame Rendering Cadence
- Screen buffer diffing updates only dirty cells, writing minimal ANSI escape bytes.
- Incremental vs full repaint statistics are tracked in `private$.frame_stats`.

## 2. Memory & Capacity Bounds
- Event queues and stream buffers enforce strict capacity ceilings.
- Input validation via `check_count()` prevents integer overflow or unbounded memory allocation from invalid arguments.\n