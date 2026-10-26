#' @title ProcessView widget
#' @description Runs a program and shows its output. See [process_view()].
#' @rdname ProcessView-class
#' @export
ProcessView <- R6::R6Class(
  "ProcessView",
  inherit = Vertical,
  public = list(
    #' @field command,args,wd,env,timeout The process to run.
    command = NULL,
    args = character(),
    wd = NULL,
    env = NULL,
    timeout = NULL,
    #' @field stop_grace `NULL` for the existing synchronous cancellation;
    #'   a number opts into non-blocking cancellation with escalation.
    stop_grace = NULL,
    #' @field supervision Process supervision policy (`"none"` or `"parent"`).
    supervision = "none",
    #' @field autostart Start when the widget is mounted?
    autostart = TRUE,
    #' @field worker The [Worker] of the current run, or `NULL`.
    worker = NULL,

    #' @description Create a process view. See [process_view()].
    #' @param command,args,wd,env,timeout The process to run.
    #' @param autostart Start when mounted?
    #' @param max_lines Output lines kept.
    #' @param stop_grace,supervision See [process_view()].
    #' @param id,classes,style See [Widget].
    initialize = function(command, args = character(), wd = NULL, env = NULL, timeout = NULL,
                          autostart = TRUE, max_lines = 2000L, id = NULL, classes = NULL, style = NULL,
                          stop_grace = NULL, supervision = "none") {
      check_scalar_character(command, "command")
      if (!is.character(args)) stop("`args` must be a character vector (one element per argument).", call. = FALSE)
      check_flag(autostart)
      if (!is.null(stop_grace)) stop_grace <- check_worker_grace(stop_grace, "stop_grace")
      supervision <- check_worker_supervision(supervision)
      private$.status <- Label$new("not started", style = style(foreground = "$muted"))
      private$.log <- LogView$new(max_lines = max_lines, style = style(height = "1fr"))
      super$initialize(private$.status, private$.log, id = id, classes = classes, style = style)
      self$command <- command
      self$args <- args
      self$wd <- wd
      self$env <- env
      self$timeout <- timeout
      self$stop_grace <- stop_grace
      self$supervision <- supervision
      self$autostart <- autostart
      self$on("worker.cancelled", function(event, app) {
        run <- private$.run
        if (!is.null(self$stop_grace) && !is.null(run) && identical(run$worker, event$data$worker)) {
          private$finished(run, NA_integer_)
        }
      })
    },

    #' @description Ctrl+X cancels the process, Ctrl+R restarts it.
    default_bindings = function() {
      list(bind("ctrl+x", "cancel_process", "Cancel process"), bind("ctrl+r", "restart_process", "Restart process"))
    },

    #' @description Start the process when the widget is mounted.
    #' @param event A `MountEvent`.
    on_mount = function(event) {
      if (self$autostart && is.null(self$worker)) self$start()
    },

    #' @description Run the process (output starts afresh).
    start = function() {
      app <- self$app
      if (is.null(app)) stop("The process view is not attached to an app.", call. = FALSE)
      if (self$running) stop("The process is already running.", call. = FALSE)
      previous_run <- private$.run
      previous_status <- private$.exit_status
      private$.log$clear()
      private$.exit_status <- NULL
      run <- new.env(parent = emptyenv())
      run$worker <- NULL
      run$finished <- FALSE
      private$.run <- run
      private$.restart_after <- NULL
      view <- self
      worker <- tryCatch(
        app$run_process(
          self$command, self$args, wd = self$wd, env = self$env, timeout = self$timeout,
          owner = self, supervision = self$supervision,
          on_stdout = function(line, app) view$.__enclos_env__$private$.log$write(line),
          on_stderr = function(line, app) view$.__enclos_env__$private$.log$write(line, level = "error"),
          on_exit = function(status, app) view$.__enclos_env__$private$finished(run, status)
        ),
        error = function(e) {
          if (identical(private$.run, run)) {
            private$.run <- previous_run
            private$.exit_status <- previous_status
          }
          stop(e)
        }
      )
      run$worker <- worker
      self$worker <- worker
      private$show_status(run)
      invisible(self)
    },

    #' @description Stop the process. With the default `stop_grace = NULL`,
    #'   this keeps the existing synchronous cancellation. A configured grace
    #'   requests cancellation without blocking and escalates through Worker.
    cancel = function() {
      run <- private$.run
      if (!is.null(run) && self$running) {
        if (is.null(self$stop_grace)) {
          run$worker$cancel()
          private$finished(run, NA_integer_)
        } else {
          run$worker$request_cancel(grace = self$stop_grace)
          private$show_status(run)
        }
      }
      invisible(self)
    },

    #' @description Cancel the current process and run it again. With an
    #'   opted-in `stop_grace`, the next run starts only after this worker has
    #'   reached a terminal state.
    restart = function() {
      run <- private$.run
      if (!is.null(run) && self$running && !is.null(self$stop_grace)) {
        private$.restart_after <- run
        run$worker$request_cancel(grace = self$stop_grace)
        private$show_status(run)
        return(invisible(self))
      }
      if (self$running) self$cancel()
      self$start()
    },

    #' @description Clear the displayed output without stopping the process.
    clear_output = function() {
      private$.log$clear()
      invisible(self)
    },

    #' @description Cancel action.
    action_cancel_process = function() self$cancel(),
    #' @description Restart action.
    action_restart_process = function() self$restart()
  ),
  active = list(
    #' @field running Is the process running?
    running = function(value) {
      if (!missing(value)) read_only("running")
      !is.null(self$worker) && self$worker$is_running()
    },
    #' @field state Process state: `"pending"`, `"running"`, `"stopping"`,
    #'   `"completed"`, `"failed"` or `"cancelled"`.
    state = function(value) {
      if (!missing(value)) read_only("state")
      run <- private$.run
      if (is.null(run) || is.null(run$worker)) return("pending")
      if (identical(run$worker$state, "running") && isTRUE(run$worker$cancel_requested)) return("stopping")
      run$worker$state
    },
    #' @field exit_status Last observed process exit status, or `NA_integer_`
    #'   when cancellation did not provide an exit status.
    exit_status = function(value) if (missing(value)) private$.exit_status else read_only("exit_status"),
    #' @field output The output lines so far.
    output = function(value) if (missing(value)) private$.log$lines else read_only("output")
  ),
  private = list(
    .status = NULL,
    .log = NULL,
    .run = NULL,
    .exit_status = NULL,
    .restart_after = NULL,

    finished = function(run, status) {
      if (is.null(run) || isTRUE(run$finished)) return(invisible(FALSE))
      run$finished <- TRUE
      run$exit_status <- status
      if (identical(private$.run, run)) private$.exit_status <- status
      worker <- run$worker
      private$show_status(run)
      self$post_message("process.finished", list(
        status = status,
        state = if (is.null(worker)) NA_character_ else worker$state
      ))
      if (!is.null(private$.restart_after) && identical(private$.restart_after, run)) {
        private$.restart_after <- NULL
        self$start()
      }
      invisible(TRUE)
    },

    show_status = function(run = private$.run) {
      cmd <- paste(c(self$command, self$args), collapse = " ")
      if (is.null(run) || is.null(run$worker)) {
        private$.status$update(span("not started", style(foreground = "$muted")))
        return(invisible())
      }
      w <- run$worker
      state <- if (identical(w$state, "running") && isTRUE(w$cancel_requested)) "stopping" else w$state
      private$.status$update(switch(
        state,
        running = span(paste0("running: ", cmd), style(foreground = "$accent")),
        stopping = span(paste0("stopping: ", cmd), style(foreground = "$warning")),
        completed = span(paste0("finished: ", cmd), style(foreground = "$success")),
        cancelled = span(paste0("cancelled: ", cmd), style(foreground = "$warning")),
        span(paste0(if (isTRUE(w$timed_out)) "timed out" else "failed", " (", w$error %||% "error", "): ", cmd),
             style(foreground = "$error"))
      ))
    }
  )
)

#' Process view
#'
#' Runs an external program (without a shell) and shows its output in a
#' scrolling log: standard output as normal lines and standard error in the
#' error colour, under a one-line status. The process starts when the view
#' is mounted (or call `$start()`), is cancelled when the view is removed
#' or the app exits, and sends `"process.finished"` (`status`, `state`)
#' when it ends. Ctrl+X cancels it and Ctrl+R restarts it while the view
#' has focus. By default cancellation remains synchronous. Set `stop_grace`
#' to a number to request a non-blocking graceful stop with escalation after
#' that many seconds. `supervision = "parent"` opts into processx parent-death
#' supervision; it does not promise cleanup of arbitrary descendants.
#' **Experimental.**
#'
#' @param command The program (a path or a name on the `PATH`).
#' @param args Arguments, one element each; never interpreted by a shell.
#' @param wd Working directory (`NULL`: current).
#' @param env Named character vector of extra environment variables.
#' @param timeout Seconds before the process is stopped (`NULL`: no limit).
#' @param autostart Start when mounted?
#' @param max_lines Output lines kept.
#' @param id,classes,style Common widget arguments.
#' @param stop_grace `NULL` keeps synchronous cancellation. A finite,
#'   non-negative number opts into non-blocking cancellation; the worker first
#'   receives processx's platform interrupt and is forcefully terminated if
#'   still running at the deadline. Signal selection is not configurable.
#' @param supervision `"none"` (default) or `"parent"` to opt into processx
#'   parent-death supervision when supported. This does not guarantee that
#'   arbitrary descendant processes are terminated.
#' @return A `ProcessView` widget with `$start()`, `$cancel()`, `$restart()`,
#'   `$clear_output()`, `$running`, `$state`, `$exit_status`, `$output` and
#'   `$worker`.
#' @export
#' @examples
#' pv <- process_view(file.path(R.home("bin"), "Rscript"), c("-e", "cat('hi\\n')"),
#'                    autostart = FALSE)
#' pv$running
process_view <- function(command, args = character(), wd = NULL, env = NULL, timeout = NULL,
                         autostart = TRUE, max_lines = 2000L, id = NULL, classes = NULL, style = NULL,
                         stop_grace = NULL, supervision = "none") {
  ProcessView$new(command, args = args, wd = wd, env = env, timeout = timeout, autostart = autostart,
                  max_lines = max_lines, id = id, classes = classes, style = style,
                  stop_grace = stop_grace, supervision = supervision)
}
