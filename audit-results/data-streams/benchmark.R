pkgload::load_all(".", quiet = TRUE)
stopifnot(requireNamespace("bench", quietly = TRUE))
cat(R.version.string, "\n", Sys.info()[["sysname"]], "\n")
one <- termr_stream(history = 1000L)
for (i in 1:1000) one$emit(i)
emitters <- lapply(c(0L, 1L, 10L, 100L), function(n) {
  x <- termr_stream(history = 1000L)
  for (i in seq_len(n)) x$subscribe(function(value) invisible(NULL))
  x
})
callback <- function(value) invisible(NULL)
result <- bench::mark(
  create = termr_stream(),
  emit_0 = emitters[[1]]$emit(1L),
  latest = one$latest(),
  history_1000 = one$history(),
  callback_only = callback(1L),
  emit_1 = emitters[[2]]$emit(1L),
  emit_10 = emitters[[3]]$emit(1L),
  emit_100 = emitters[[4]]$emit(1L),
  iterations = 1000L, check = FALSE, memory = TRUE, filter_gc = FALSE
)
print(result[, c("expression", "median", "itr/sec", "mem_alloc", "gc/sec")], width = Inf)
bulk <- function() {
  x <- termr_stream(history = 1000L)
  for (i in seq_len(100000L)) x$emit(i)
  stopifnot(identical(x$latest(), 100000L), length(x$history()) == 1000L)
}
print(bench::mark(emit_100000 = bulk(), iterations = 3L, check = FALSE, filter_gc = FALSE)[,
  c("expression", "median", "itr/sec", "mem_alloc", "gc/sec")], width = Inf)
x <- termr_stream(history = 64L)
retained_bytes <- function() {
  env <- environment(x$emit)$slots
  sum(vapply(as.list(env), function(value) as.numeric(object.size(value)), 0)) + as.numeric(object.size(ls(env)))
}
for (i in 1:1000) x$emit(i)
before <- retained_bytes()
for (i in 1:100000) x$emit(i)
after <- retained_bytes()
cat("Retained slot bytes after 1k / 101k:", before, after, "slots:", length(ls(environment(x$emit)$slots)), "\n")
stopifnot(before == after)
profile <- file.path("audit-results", "data-streams", paste0("profile-", Sys.info()[["sysname"]], ".out"))
Rprof(profile, interval = 0.01, memory.profiling = TRUE)
for (i in seq_len(10L)) bulk()
Rprof(NULL)
print(utils::head(summaryRprof(profile, memory = "both")$by.total, 12))
