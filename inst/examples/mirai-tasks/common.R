# Example-local models; all runtime calls use exported termr APIs.
task_workload <- function(chunks = 80L, progress) {
  total <- 0
  for (i in seq_len(chunks)) {
    total <- total + sum(sqrt(seq_len(20000L) + i))
    Sys.sleep(.025) # Pace a mixed compute/wait demonstration, not a benchmark.
    progress(i / chunks, paste("chunk", i, "of", chunks))
  }
  total
}

task_demo_model <- function(workers = 2L, limit = 12L) {
  pool <- termr::termr_mirai_pool(workers, max_pending = limit, history = 128L)
  tasks <- list(); events <- list()
  subscription <- pool$events$subscribe(function(event) events <<- utils::tail(c(events, list(event)), 64L))
  submit <- function(fail = FALSE, chunks = 80L) {
    if (length(tasks) >= limit) {
      removable <- which(vapply(tasks, function(task) task$ready(), logical(1)))
      if (!length(removable)) stop("All retained tasks are active; wait or cancel one.")
      tasks <<- tasks[-removable[[1L]]]
    }
    task <- if (fail) pool$submit(function() stop("Demonstration task failure"), task_type = "failure") else
      pool$submit(task_workload, args = list(chunks = chunks), progress = TRUE, task_type = "chunked calculation", timeout = 30)
    tasks[[length(tasks) + 1L]] <<- task
    invisible(task)
  }
  snapshot <- function() {
    pool$poll()
    rows <- lapply(tasks, function(task) {
      info <- task$info()
      info$error <- if (is.null(info$error)) NULL else substr(info$error, 1L, 256L)
      info$duration <- (if (is.null(info$finished_at)) as.numeric(Sys.time()) else info$finished_at) - info$submitted_at
      info
    })
    pending <- vapply(rows, `[[`, "", "status")
    counters <- pool$diagnostics()$counters
    list(timestamp = as.numeric(Sys.time()), tasks = rows, history = utils::tail(events, 32L),
      counts = list(queued = sum(pending == "queued"), running = sum(pending == "running"),
        completed = counters$completed, failed = counters$failed,
        cancelled = counters$cancelled, timed_out = counters$timed_out))
  }
  cancel <- function(index = 1L) {
    active <- Filter(function(task) !task$ready(), tasks)
    if (length(active) >= index) active[[index]]$cancel() else invisible(FALSE)
  }
  list(pool = pool, submit = submit, snapshot = snapshot, cancel = cancel,
    close = function() {pool$close(); subscription$unsubscribe()})
}

task_rows <- function(snapshot) {
  if (is.null(snapshot) || !length(snapshot$tasks)) return(data.frame(task = character(), status = character(), duration = numeric(), progress = numeric(), error = character()))
  do.call(rbind, lapply(seq_along(snapshot$tasks), function(i) {
    task <- snapshot$tasks[[i]]
    data.frame(task = paste0(i, ": ", task$task_type), status = task$status,
      duration = round(task$duration, 2), progress = if (is.null(task$progress)) NA_real_ else task$progress,
      error = if (is.null(task$error)) "" else task$error)
  }))
}
