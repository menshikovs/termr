source("audit-results/mirai/environment.R")
library(termr)
base <- file.path(root, "audit-results/mirai")
elapsed <- function() proc.time()[["elapsed"]]
quant <- function(x) unname(quantile(x, c(.5, .95)))
main <- function() {
  results <- list()
  for (workers in c(1L, 2L, 4L, 8L)) {
    start <- elapsed(); pool <- termr_mirai_pool(workers, max_pending = 128L, history = 32L)
    on.exit(pool$close(), add = TRUE)
    cold <- elapsed() - start
    private <- attr(pool, "termr_mirai", exact = TRUE)
    probes <- mirai::everywhere(list(pid = Sys.getpid(), rss = unname(ps::ps_memory_info()[["rss"]])), .min = workers, .compute = private$profile)
    deadline <- elapsed() + 15
    while (any(vapply(probes, mirai::unresolved, logical(1)))) {
      if (elapsed() > deadline) stop("Worker memory probe timeout")
      Sys.sleep(.005)
    }
    workers_info <- lapply(probes, function(m) m$data)
    submit <- rtt <- numeric()
    for (i in 1:40) {
      start <- elapsed(); task <- pool$submit(function(x) x + 1L, args = list(x = i)); sent <- elapsed()
      task$wait(10); stopifnot(task$result() == i + 1L)
      submit <- c(submit, (sent - start) * 1000); rtt <- c(rtt, (elapsed() - start) * 1000)
    }
    start <- elapsed()
    jobs <- lapply(1:100, function(i) pool$submit(function(n) sum(sqrt(seq_len(n))), args = list(n = 200000L)))
    for (task in jobs) task$wait(30)
    throughput <- 100 / (elapsed() - start)
    results[[length(results) + 1L]] <- list(workers = workers, cold_seconds = cold,
      submission_ms = quant(submit), round_trip_ms = quant(rtt), throughput_tasks_sec = throughput,
      worker_memory = workers_info, diagnostics = pool$diagnostics())
    pool$close()
  }

  pool <- termr_mirai_pool(2L, max_pending = 32L, history = 64L, max_input_bytes = 32 * 1024^2)
  on.exit(pool$close(), add = TRUE)
  sizes <- c(0L, 1024L, 1024L^2, 8L * 1024L^2)
  serialization <- lapply(sizes, function(size) {
    object <- raw(size)
    plain <- submit <- numeric()
    for (i in 1:5) {
      start <- elapsed(); bytes <- serialize(list(x = object), NULL, version = 3L); plain <- c(plain, (elapsed() - start) * 1000)
      start <- elapsed(); task <- pool$submit(function(x) length(x), args = list(x = object)); submit <- c(submit, (elapsed() - start) * 1000)
      task$wait(15); stopifnot(task$result() == size)
    }
    list(bytes = size, serialization_ms = quant(plain), submission_ms = quant(submit))
  })
  # Comparable single-job call/result comparison; processx starts a fresh worker.
  pilot <- test_app(app(label("benchmark")), 20, 2)
  on.exit(pilot$stop(), add = TRUE)
  comparison <- lapply(c(1000L, 100000L, 1000000L), function(n) {
    fn <- function(n) sum(sqrt(seq_len(n)))
    start <- elapsed(); expected <- fn(n); inline <- elapsed() - start
    start <- elapsed(); task <- pool$submit(fn, args = list(n = n)); task$wait(20); mirai_time <- elapsed() - start
    start <- elapsed(); worker <- pilot$app$run_worker(fn, args = list(n = n)); pilot$wait_for_workers(30); processx_time <- elapsed() - start
    stopifnot(identical(task$result(), expected), identical(worker$result, expected))
    list(n = n, main_seconds = inline, mirai_warm_seconds = mirai_time, processx_cold_seconds = processx_time)
  })
  crossover <- lapply(c(1000L, 100000L, 1000000L, 5000000L), function(n) {
    fn <- function(n) sum(sqrt(seq_len(n)))
    start <- elapsed(); plain <- lapply(1:8, function(i) fn(n)); main_time <- elapsed() - start
    start <- elapsed(); tasks <- lapply(1:8, function(i) pool$submit(fn, args = list(n = n)))
    for (task in tasks) task$wait(30)
    async_time <- elapsed() - start
    stopifnot(all(vapply(tasks, function(task) identical(task$result(), plain[[1L]]), logical(1))))
    list(n = n, tasks = 8L, workers = 2L, main_seconds = main_time, mirai_seconds = async_time)
  })
  # One-minute bounded-handle/RSS observation; 1000+ short jobs, no browser.
  rss <- numeric(); times <- numeric(); completed <- 0L; start <- elapsed()
  while (elapsed() - start < 60) {
    tasks <- lapply(1:20, function(i) pool$submit(function() sum(sqrt(seq_len(20000L)))))
    for (task in tasks) task$wait(15)
    completed <- completed + length(tasks)
    rss <- c(rss, unname(ps::ps_memory_info()[["rss"]]) / 1024^2); times <- c(times, elapsed() - start)
    Sys.sleep(.15)
  }
  memory <- list(seconds = elapsed() - start, completed = completed, rss_mib = rss, at = times,
    retained_history = length(pool$events$history()), pending = pool$diagnostics()$pending)
  stopifnot(memory$retained_history <= 64L, memory$pending == 0L)
  pool$close()

  # Progress delivery and TUI event-loop latency, with all daemons busy.
  env <- new.env(); source("inst/examples/mirai-tasks/tui.R", local = env)
  demo <- env$task_monitor(2L, 4L, chunks = 160L)
  on.exit(demo$close(), add = TRUE)
  tui <- test_app(demo$app, 100, 16); on.exit(tui$stop(), add = TRUE)
  latency <- numeric(); events <- list()
  subscription <- demo$model$pool$events$subscribe(function(event) if (event$event == "task_progress")
    events[[length(events) + 1L]] <<- list(received_at = as.numeric(Sys.time()), event = event))
  on.exit(subscription$unsubscribe(), add = TRUE)
  for (i in 1:60) {
    start <- elapsed(); tui$press("i"); latency <- c(latency, (elapsed() - start) * 1000)
    tui$advance(.05); Sys.sleep(.02)
  }
  stopifnot(grepl("60", tui$query_one("#inputs")$text, fixed = TRUE))
  delivery <- vapply(events, function(x) (x$received_at - x$event$reported_at) * 1000, 0)
  progress <- list(events = length(events), delivery_ms = if (length(delivery)) quant(delivery) else numeric(), key_to_render_ms = quant(latency),
    history = length(demo$model$pool$events$history()))
  demo$close()
  jsonlite::write_json(list(platform = host, pools = results, serialization = serialization,
    comparison = comparison, parallel_crossover = crossover, memory = memory, progress_tui = progress),
    file.path(base, paste0("performance-", host, ".json")), auto_unbox = TRUE, null = "null", pretty = TRUE)
  cat("PASS 1/2/4/8-worker performance, serialization, comparable processx jobs, minute RSS and TUI latency\n")
}
main()
