host <- if (.Platform$OS.type == "windows") "windows" else "wsl"
.libPaths(c(file.path("audit-results/nanonext", paste0("lib-", host)), .libPaths()))
library(termr)
cat(R.version.string, "nanonext", as.character(packageVersion("nanonext")), "\n")
# Internal codec profiling is an implementation audit, not application API.
encode <- getFromNamespace("nano_encode", "termr")
decode <- getFromNamespace("nano_decode", "termr")
message <- list(schema_version = 1L, source_id = "benchmark", stream_id = "bench",
  sequence = 1, timestamp = as.numeric(Sys.time()), message_type = "event", payload = list(cpu = 42.5, ram = 61.2))
wire <- encode(message, 1048576L)
plain <- termr_stream("plain", history = 64L)
published <- termr_stream("published", history = 64L)
p <- termr_nano_publish(published, "tcp://127.0.0.1:0")
dispatch <- termr_stream("dispatch", history = 0L)
dispatch$subscribe(function(x) invisible(NULL))
source("inst/examples/system-monitor-live/common.R")
dir <- tempfile("nano-file-benchmark-"); dir.create(dir)
writer <- monitor_writer(dir, min_interval = 0)
snapshot <- monitor_collector("benchmark")()
result <- bench::mark(
  emit_local = plain$emit(message$payload),
  emit_publisher = published$emit(message$payload),
  encoding = encode(message, 1048576L),
  decoding_validation = decode(wire, 1048576L),
  dispatch_one_callback = dispatch$emit(message$payload),
  file_publish = writer$publish(snapshot),
  file_read_validate = monitor_read(dir),
  iterations = 500L, check = FALSE, filter_gc = FALSE
)
print(result[, c("expression", "median", "itr/sec", "mem_alloc", "gc/sec")], width = Inf)
cat("Wire bytes", length(wire), "\n")
before <- ps::ps_memory_info()[["rss"]]
for (i in 1:10000) published$emit(list(n = i))
gc()
after <- ps::ps_memory_info()[["rss"]]
cat("RSS before/after 10000 publications", before, after, "history", length(published$history()), "pending", p$status()$pending, "\n")
writer$close(); p$close(); plain$close(); published$close(); dispatch$close()
