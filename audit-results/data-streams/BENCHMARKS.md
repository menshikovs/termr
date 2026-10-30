# Benchmarks

Run on this shared development host on 2026-10-29 with bench::mark and Rprof;
Windows R 4.6.1 UCRT, WSL Ubuntu R 4.5.2. These are observed local timings,
not throughput guarantees or isolated hardware comparisons. Other validation
processes were active. Each microbenchmark used 1000 iterations, check=FALSE,
filter_gc=FALSE. Bulk emission used three iterations. Scripts and raw output:
benchmark.R, benchmark-windows-final.log, benchmark-wsl-final.log.

| Operation | Windows median | WSL median |
| --- | ---: | ---: |
| Create stream | 7.70 us | 6.22 us |
| Emit, 0 subscribers | 3.90 us | 3.77 us |
| latest | 0.600 us | 0.455 us |
| history, 1000 events | 2.40 ms | 1.97 ms |
| No-op callback alone | 0.100 us | 0.157 us |
| Emit, 1 subscriber | 10.7 us | 10.25 us |
| Emit, 10 subscribers | 77.3 us | 64.18 us |
| Emit, 100 subscribers | 721.3 us | 629.67 us |
| 100000 emits, no subscribers | 393 ms | 367 ms |

The callback-only row is separate: delivery includes registry lookup,
untracked reactive isolation, protected dispatch and the callback. Real
application callback work is extra. No deep payload cloning is performed.

bench allocation: creation 840 B; warmed emit/latest/no-op delivery reported
0 B per operation; history(1000) allocated 19.7 KiB; a whole 100000-event
run allocated about 181-182 KiB as reported by bench. These are allocation
measurements and not the maximum payload size or resident memory usage.

Memory invariant: capacity 64 retained exactly 64 slots, 7728 measured bytes
of slot values plus slot names both after 1000 and after 101000 publications,
on both platforms. This excludes environment overhead, closures and arbitrary
payload sizes. test-streams also verifies no subscriber registrations remain
after 1000 subscribe/unsubscribe cycles and uses GC finalizers to verify
callback and event object release on unsubscribe/clear/close.

Rprof samples are saved as profile-Windows.out and profile-Linux.out. The
final profiles use a 10 ms interval over ten bulk runs (one million events).
Linux attributes 83.7% inclusive time to emit (48.5% self), 29.9% inclusive to
assign and 11.2% to slot-key conversion. Windows attributes 84.4% inclusive to
emit (45.8% self), 32.4% inclusive to assign and 16.4% to slot-key conversion.
The initial Windows 1 ms profile yielded no samples; 10 ms resolves that
sampling issue. No performance optimization was made solely from timings.
