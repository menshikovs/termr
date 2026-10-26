# Characterize worker contracts from an installed termr 1.0.1 package.
#
# Point TERMR_CRAN_LIB at an isolated library containing the CRAN-installed
# package. This script deliberately refuses a package without CRAN install
# metadata or the exact CRAN archive URL recorded by remotes::install_url(),
# so a local build with the same version is not mistaken for CRAN.

library_path <- Sys.getenv("TERMR_CRAN_LIB")
if (!nzchar(library_path) || !dir.exists(library_path)) {
  stop("Set TERMR_CRAN_LIB to the isolated library containing termr 1.0.1.", call. = FALSE)
}
.libPaths(c(normalizePath(library_path), .libPaths()))

description <- packageDescription("termr", lib.loc = library_path)
cran_archive_url <- "https://cloud.r-project.org/src/contrib/Archive/termr/termr_1.0.1.tar.gz"
standard_cran_install <- !is.null(description) &&
  identical(description$Repository, "CRAN") &&
  identical(description$RemoteType, "standard")
archive_cran_install <- !is.null(description) &&
  identical(description$RemoteType, "url") &&
  identical(description$RemoteUrl, cran_archive_url) &&
  identical(Sys.getenv("TERMR_CRAN_ARCHIVE_URL"), cran_archive_url)
if (is.null(description) || !identical(description$Version, "1.0.1") ||
    !(standard_cran_install || archive_cran_install)) {
  stop("The selected package must be the CRAN-installed termr 1.0.1 artifact.", call. = FALSE)
}

library(termr)

worker_probe <- Worker$new("baseline-cancel")
app_probe <- App$new()

report <- list(
  runtime = list(
    R = as.character(getRversion()),
    platform = R.version$platform,
    os = Sys.info()[c("sysname", "release", "version", "machine")],
    termr_version = description$Version,
    built = description$Built,
    repository = description$Repository,
    remote_type = description$RemoteType,
    remote_sha = description$RemoteSha,
    processx = as.character(packageVersion("processx")),
    ps = as.character(packageVersion("ps")),
    R6 = as.character(packageVersion("R6"))
  ),
  APIs = list(
    exports = sort(getNamespaceExports("termr")),
    app = formals(app),
    run_worker = formals(run_worker),
    run_process = formals(run_process),
    Worker_fields = setdiff(ls(worker_probe, all.names = TRUE),
                            c(".__enclos_env__", "initialize", "cancel", "is_running", "pid", "print", "clone")),
    Worker_methods = intersect(ls(worker_probe, all.names = TRUE),
                               c("initialize", "cancel", "is_running", "pid", "print", "clone")),
    App_methods = intersect(ls(app_probe, all.names = TRUE),
                            c("run", "exit", "run_worker", "run_process", "workers"))
  )
)

events <- character()
complete_calls <- 0L
error_calls <- 0L
application <- app(
  label("baseline"),
  on("*", function(event, app) {
    if (startsWith(event$type, "worker.")) events <<- c(events, event$type)
  })
)
pilot <- test_app(application, width = 20, height = 1)
on.exit(pilot$stop(), add = TRUE)

completed <- application$run_worker(
  function() 42L,
  inline = TRUE,
  on_complete = function(result, app) {
    stopifnot(identical(result, 42L))
    complete_calls <<- complete_calls + 1L
  },
  on_error = function(message, app) error_calls <<- error_calls + 1L
)
pilot$step()
stopifnot(identical(completed$state, "completed"),
          identical(completed$result, 42L),
          identical(complete_calls, 1L), identical(error_calls, 0L),
          identical(events, c("worker.started", "worker.completed")),
          identical(completed$cancel(), FALSE))

standalone_cancel <- Worker$new("baseline-cancel")
first_cancel <- standalone_cancel$cancel()
second_cancel <- standalone_cancel$cancel()
stopifnot(identical(first_cancel, TRUE), identical(second_cancel, FALSE),
          identical(standalone_cancel$state, "cancelled"))

report$observed <- list(
  inline_success = list(state = completed$state, result = completed$result,
                        events = events, on_complete_calls = complete_calls,
                        on_error_calls = error_calls,
                        cancel_after_terminal = FALSE),
  standalone_cancel = list(first_return = first_cancel, second_return = second_cancel,
                           state = standalone_cancel$state),
  process_probe = "not run (set TERMR_RUN_PROCESS_PROBE=true to run real-child probes)"
)

if (identical(tolower(Sys.getenv("TERMR_RUN_PROCESS_PROBE")), "true")) {
  process_app <- app(label("process probe"))
  process_pilot <- test_app(process_app, width = 20, height = 1)
  process_worker <- NULL
  process_started <- proc.time()[["elapsed"]]
  process_result <- tryCatch({
    process_worker <- process_app$run_process(
      file.path(R.home("bin"), if (.Platform$OS.type == "windows") "Rscript.exe" else "Rscript"),
      c("-e", "Sys.sleep(30)")
    )
    process_pid <- process_worker$pid()
    cancel_started <- proc.time()[["elapsed"]]
    cancel_return <- process_worker$cancel(grace = 0.3)
    cancel_elapsed <- proc.time()[["elapsed"]] - cancel_started
    process_pilot$step()
    list(started = TRUE, pid = process_pid, cancel_return = cancel_return,
         cancel_elapsed_seconds = cancel_elapsed, state = process_worker$state)
  }, error = function(e) list(started = FALSE, error = conditionMessage(e)))
  if (!is.null(process_worker) && process_worker$is_running()) {
    process_worker$cancel(grace = 0)
  }
  process_pilot$stop()
  report$observed$process_probe <- process_result
  report$observed$process_probe_elapsed_seconds <- proc.time()[["elapsed"]] - process_started
}

if (identical(tolower(Sys.getenv("TERMR_REQUIRE_PROCESS_PROBE")), "true")) {
  process_result <- report$observed$process_probe
  if (!is.list(process_result) || !isTRUE(process_result$started)) {
    stop("A real child process was required, but the process probe did not start: ",
         if (is.list(process_result)) process_result$error else process_result,
         call. = FALSE)
  }
  if (!identical(process_result$cancel_return, TRUE) ||
      !identical(process_result$state, "cancelled")) {
    stop("The real-child synchronous cancellation probe did not finish as cancelled.",
         call. = FALSE)
  }
}

cat("CRAN termr 1.0.1 worker lifecycle characterization\n")
dput(report)
