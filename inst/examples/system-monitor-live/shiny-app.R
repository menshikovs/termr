# Run with Rscript shiny-app.R [snapshot-directory]. Binds loopback only.
source_files <- Filter(Negate(is.null), lapply(sys.frames(), function(f) f$ofile))
local_file <- if (length(source_files)) tail(source_files, 1L)[[1L]] else sub("^--file=", "", grep("^--file=", commandArgs(), value = TRUE)[1L])
source(file.path(dirname(local_file), "common.R"), local = TRUE)

monitor_server <- function(path = monitor_path(), stale_after = 5) {
  force(path)
  function(input, output, session) {
    client <- monitor_client(path, stale_after = stale_after)
    session$onSessionEnded(function() client$close())
    # A time bucket changes even without new files, so stale status advances.
    clock <- shiny::reactivePoll(if (Sys.getenv("TERMR_METRICS_TRANSPORT", "file") == "nano") 50 else 500, session,
      checkFunc = function() as.numeric(Sys.time()),
      valueFunc = function() as.numeric(Sys.time()))
    current <- shiny::reactive({ clock(); client$poll() })
    output$status <- shiny::renderText(monitor_status(current()))
    output$metrics <- shiny::renderText({
      x <- current()$snapshot
      paste("CPU:", monitor_format(x$metrics$cpu), "RAM:", monitor_format(x$metrics$ram))
    })
    output$history <- shiny::renderPlot({
      current()
      points <- client$stream$history()
      if (!length(points)) { graphics::plot.new(); graphics::title("Waiting for collector"); return(invisible(NULL)) }
      times <- as.POSIXct(vapply(points, `[[`, 0, "timestamp"), origin = "1970-01-01")
      values <- vapply(points, function(x) c(CPU = if (is.null(x$metrics$cpu)) NA_real_ else x$metrics$cpu,
                                            RAM = if (is.null(x$metrics$ram)) NA_real_ else x$metrics$ram), numeric(2))
      graphics::matplot(times, t(values), type = "o", ylim = c(0, 100), xlab = "Time", ylab = "Percent", pch = 20)
      graphics::legend("topright", c("CPU", "RAM"), col = 1:2, lty = 1:2)
    })
  }
}

monitor_shiny <- function(path = monitor_path()) {
  if (!requireNamespace("shiny", quietly = TRUE)) stop("Install optional package 'shiny'.")
  shiny::shinyApp(shiny::fluidPage(shiny::titlePanel("termr live system monitor"),
    shiny::textOutput("status"), shiny::textOutput("metrics"), shiny::plotOutput("history")),
    monitor_server(path))
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  dashboard <- monitor_shiny(if (length(args)) args[[1L]] else monitor_path())
  shiny::runApp(dashboard, host = "127.0.0.1", port = 3838L, launch.browser = FALSE)
}
