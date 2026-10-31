# Invoke as: stream-benchmark.R after stream
source('audit-results/hardening/h3-performance/benchmark-frozen.R')
measure('continuous-stream', 384L, stream_setup, stream_run, function(x) {x$p$stop(); x$s$close()})
