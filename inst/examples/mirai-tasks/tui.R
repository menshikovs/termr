# Rscript inst/examples/mirai-tasks/tui.R [workers=2]
source_files <- Filter(Negate(is.null), lapply(sys.frames(), function(f) f$ofile))
local_file <- if (length(source_files)) tail(source_files, 1L)[[1L]] else sub("^--file=", "", grep("^--file=", commandArgs(), value = TRUE)[1L])
source(file.path(dirname(local_file), "common.R"), local = TRUE)

task_monitor <- function(workers = 2L, initial = 4L, chunks = 120L) {
  model <- task_demo_model(workers)
  ready <- FALSE; on.exit(if (!ready) model$close(), add = TRUE)
  for (i in seq_len(initial)) model$submit(chunks = chunks)
  inputs <- 0L
  view <- termr::app(termr::vertical(
    termr::label("mirai task monitor", style = termr::style(bold = TRUE)),
    termr::label("n submit  e fail  c cancel first active  i input probe  q quit"),
    termr::label("Input probe: 0", id = "inputs"),
    termr::label("", id = "counts"),
    termr::label("", id = "tasks", style = termr::style(height = "1fr")),
    termr::label("", id = "recent")),
    termr::bind("q", "quit"),
    termr::bind("c", function(app) model$cancel()),
    termr::bind("n", function(app) tryCatch(model$submit(), error = function(e) app$notify(conditionMessage(e)))),
    termr::bind("e", function(app) tryCatch(model$submit(TRUE), error = function(e) app$notify(conditionMessage(e)))),
    termr::bind("i", function(app) {
      inputs <<- inputs + 1L
      app$query_one("#inputs")$update(paste("Input probe:", inputs))
    }), termr::on("unmount", function(event, app) model$close()))
  update <- function(app) {
    value <- model$snapshot(); rows <- task_rows(value)
    app$query_one("#counts")$update(paste(names(value$counts), unlist(value$counts), collapse = " | "))
    lines <- vapply(seq_len(nrow(rows)), function(i) sprintf("%-24s %-10s %6.2fs %s %s", rows$task[[i]], rows$status[[i]],
      rows$duration[[i]], if (is.na(rows$progress[[i]])) "?" else sprintf("%3.0f%%", 100 * rows$progress[[i]]), rows$error[[i]]), "")
    app$query_one("#tasks")$update(paste(lines, collapse = "\n"))
    recent <- utils::tail(value$history, 3L)
    app$query_one("#recent")$update(paste(vapply(recent, function(x) paste(x$event, x$message), ""), collapse = "\n"))
  }
  view$set_interval(.05, update); view$call_later(update)
  ready <- TRUE
  list(app = view, model = model, close = model$close)
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  demo <- task_monitor(if (length(args)) as.integer(args[[1L]]) else 2L)
  tryCatch(termr::run(demo$app), finally = demo$close())
}
