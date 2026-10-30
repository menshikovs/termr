source("audit-results/mirai/environment.R")
library(termr)
base <- file.path(root, "audit-results/mirai")
wait_all <- function(tasks, pool, seconds = 60) {
  deadline <- proc.time()[["elapsed"]] + seconds
  while (!all(vapply(tasks, function(task) task$ready(), logical(1)))) {
    pool$poll()
    if (proc.time()[["elapsed"]] > deadline) stop("Stress deadline exceeded")
    Sys.sleep(.001)
  }
}
main <- function() {
  set.seed(20261030)
  pool <- termr_mirai_pool(4L, max_pending = 128L, history = 64L, seed = 20261030L)
  on.exit(pool$close(), add = TRUE)
  start <- proc.time()[["elapsed"]]
  pids <- integer(); accepted <- 0L
  for (batch in 1:10) {
    tasks <- lapply(1:100, function(i) pool$submit(function(n) list(pid = Sys.getpid(), value = n + 1L), args = list(n = i)))
    wait_all(tasks, pool)
    stopifnot(all(vapply(seq_along(tasks), function(i) identical(tasks[[i]]$result()$value, i + 1L), logical(1))))
    pids <- union(pids, vapply(tasks, function(task) task$result()$pid, 0L))
    accepted <- accepted + length(tasks)
    stopifnot(length(pool$events$history()) <= 64L, pool$diagnostics()$pending == 0L)
  }
  thousand <- list(tasks = accepted, seconds = proc.time()[["elapsed"]] - start, worker_pids = pids,
    diagnostic = pool$diagnostics())
  stopifnot(length(pids) <= 4L)
  pool$close()

  queued <- termr_mirai_pool(2L, max_pending = 100L, history = 32L)
  on.exit(queued$close(), add = TRUE)
  hundred <- lapply(1:100, function(i) queued$submit(function() Sys.sleep(20)))
  limit <- tryCatch({queued$submit(function() 1); FALSE}, error = function(e) grepl("pending task limit", conditionMessage(e)))
  stopifnot(limit, queued$diagnostics()$pending == 100L)
  queued_status <- queued$diagnostics()
  queued$close()
  stopifnot(all(vapply(hundred, function(task) task$status() == "cancelled", logical(1))), queued$diagnostics()$pending == 0L)

  fuzz <- termr_mirai_pool(2L, max_pending = 64L, history = 2048L, progress_interval = .01, seed = 8128L)
  on.exit(fuzz$close(), add = TRUE)
  tasks <- lapply(1:60, function(i) fuzz$submit(function(n, progress) {
    for (j in 1:5) {Sys.sleep(.005); progress(j / 5)}
    if (n %% 7L == 0L) stop("seeded failure")
    n
  }, args = list(n = i), progress = TRUE, timeout = if (i %% 11L == 0L) .02 else 10))
  cancelled <- sample(seq_along(tasks), 20L)
  for (i in cancelled) {tasks[[i]]$cancel(); stopifnot(!tasks[[i]]$cancel())}
  wait_all(tasks, fuzz, 30)
  events <- fuzz$events$history()
  terminal <- Filter(function(event) event$event %in% c("task_completed", "task_failed", "task_cancelled", "task_timed_out"), events)
  ids <- vapply(terminal, `[[`, "", "task_id")
  stopifnot(length(ids) == 60L, !anyDuplicated(ids), fuzz$diagnostics()$pending == 0L)
  for (i in 1:100) {
    subscription <- fuzz$events$subscribe(function(event) invisible(NULL)); subscription$unsubscribe(); subscription$unsubscribe()
  }
  stopifnot(fuzz$events$subscriber_count() == 0L)
  states <- table(vapply(tasks, function(task) task$status(), ""))
  fuzz_result <- list(states = as.list(stats::setNames(as.integer(states), names(states))), diagnostic = fuzz$diagnostics())

  # Malformed raw JSON and hostile field shapes through the real native socket.
  private <- attr(fuzz, "termr_mirai", exact = TRUE)
  push <- nanonext::socket("push")
  on.exit(close(push), add = TRUE)
  nanonext::opt(push, "send-buffer") <- 128L
  nanonext::dial(push, private$endpoint, fail = "error")
  payloads <- c(list(charToRaw("{bad"), charToRaw('{"version":1,"pool_id":[]}'), as.raw(0)),
    lapply(1:200, function(i) as.raw(sample(0:255, sample(1:2048, 1), replace = TRUE))))
  for (wire in payloads) {nanonext::send(push, wire, mode = "raw", block = FALSE); fuzz$poll(max_messages = 4L)}
  deadline <- proc.time()[["elapsed"]] + .2
  while (proc.time()[["elapsed"]] < deadline) {fuzz$poll(max_messages = 4L); Sys.sleep(.001)}
  stopifnot(fuzz$diagnostics()$invalid_progress > 0, fuzz$diagnostics()$pending == 0L)
  fuzz_result$after_raw <- fuzz$diagnostics()
  fuzz$close()
  admission <- termr_mirai_pool(1L, memory = 1, max_pending = 32L, max_input_bytes = 2 * 1024^2)
  on.exit(admission$close(), add = TRUE)
  error <- NULL; start_admission <- proc.time()[["elapsed"]]
  for (i in 1:20) {
    result <- tryCatch(admission$submit(function(x) {Sys.sleep(5); length(x)}, args = list(x = raw(800000L))), error = identity)
    if (inherits(result, "error")) {error <- conditionMessage(result); break}
  }
  stopifnot(!is.null(error), grepl("dispatcher memory capacity", error, fixed = TRUE))
  backpressure <- list(error = error, seconds = proc.time()[["elapsed"]] - start_admission, diagnostic = admission$diagnostics())
  admission$close()
  jsonlite::write_json(list(platform = host, seed = 20261030L, thousand = thousand,
    queued100 = queued_status, fuzz = fuzz_result, backpressure = backpressure), file.path(base, paste0("stress-", host, ".json")),
    auto_unbox = TRUE, null = "null", pretty = TRUE)
  cat("PASS 1000 tasks / <=4 workers; 100 pending / 2 workers; seeded cancellation/error/timeout; raw fuzz; repeated subscriptions\n")
}
main()
