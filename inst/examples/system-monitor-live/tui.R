# Run with Rscript tui.R [snapshot-directory]. Only this process owns a terminal.
source_files <- Filter(Negate(is.null), lapply(sys.frames(), function(f) f$ofile))
local_file <- if (length(source_files)) tail(source_files, 1L)[[1L]] else sub("^--file=", "", grep("^--file=", commandArgs(), value = TRUE)[1L])
source(file.path(dirname(local_file), "common.R"), local = TRUE)

monitor_tui <- function(path = monitor_path(), stale_after = 5) {
  client <- monitor_client(path, stale_after = stale_after)
  reading <- termr::signal(list(status = "unavailable", snapshot = NULL, missed = 0))
  view <- termr::app(
    termr::vertical(
      termr::label("Live system monitor", style = termr::style(bold = TRUE)),
      termr::label(function() monitor_status(reading()), id = "source"),
      termr::label(function() {
        x <- reading()$snapshot
        paste("CPU:", monitor_format(x$metrics$cpu), "RAM:", monitor_format(x$metrics$ram))
      }, id = "metrics"),
      termr::label("", id = "processes", style = termr::style(height = "1fr")),
      termr::label("q quit (collector and Shiny continue)")
    ), termr::bind("q", "quit"),
    termr::on("unmount", function() client$close())
  )
  update <- function(app) {
    value <- client$poll()
    reading(value)
    records <- value$snapshot$metrics$processes
    text <- vapply(utils::head(records, 12L), function(p) {
      paste(p$pid, if (is.null(p$name)) "?" else p$name,
            if (is.null(p$rss)) "RSS unavailable" else sprintf("%.1f MiB", p$rss / 1024^2))
    }, character(1))
    app$query_one("#processes")$update(paste(c("Processes (largest RSS):", text), collapse = "\n"))
  }
  view$set_interval(if (Sys.getenv("TERMR_METRICS_TRANSPORT", "file") == "nano") 0.05 else 1, update)
  view$call_later(update)
  # Explicit cleanup also works when App shutdown does not dispatch unmount.
  list(app = view, close = function() { client$close(); termr::dispose(reading) }, client = client)
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  demo <- monitor_tui(if (length(args)) args[[1L]] else monitor_path())
  tryCatch(termr::run(demo$app), finally = demo$close())
}
