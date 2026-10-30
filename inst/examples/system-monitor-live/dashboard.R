# Full Shiny dashboard; Rscript dashboard.R [snapshot-directory] [auto|base|ggplot|plotly].
source_files <- Filter(Negate(is.null), lapply(sys.frames(), function(f) f$ofile))
local_file <- if (length(source_files)) tail(source_files, 1L)[[1L]] else sub("^--file=", "", grep("^--file=", commandArgs(), value = TRUE)[1L])
source(file.path(dirname(local_file), "common.R"), local = TRUE)
source(file.path(dirname(local_file), "visualization.R"), local = TRUE)

monitor_dashboard_source <- function(path, transport, endpoint, snapshot_endpoint, max_points) {
  if (transport == "nano") return(termr::termr_nano_connect(endpoint, "system.metrics",
    if (nzchar(snapshot_endpoint)) snapshot_endpoint else NULL, history = max_points, request_timeout = 3000L))
  if (transport != "file") stop("Dashboard transport must be file or nano.")
  client <- monitor_client(path, history = max_points, transport = "file")
  reading <- list(status = "unavailable", missed = 0, message = NULL)
  list(latest = client$stream$latest, history = client$stream$history,
    subscribe = client$stream$subscribe, close = client$close, is_closed = client$stream$is_closed,
    poll = function() {reading <<- client$poll(); invisible(NULL)},
    status = function() list(state = reading$status, gaps = reading$missed,
      last_error = reading$message))
}

monitor_dashboard <- function(path = monitor_path(), mode = "auto", max_points = 600L,
                              transport = Sys.getenv("TERMR_METRICS_TRANSPORT", "file"),
                              endpoint = Sys.getenv("TERMR_METRICS_ENDPOINT", "tcp://127.0.0.1:5555"),
                              snapshot_endpoint = Sys.getenv("TERMR_METRICS_SNAPSHOT_ENDPOINT", ""),
                              probe = Sys.getenv("TERMR_BROWSER_PROBE", "") == "1",
                              interval = 500L) {
  if (!requireNamespace("shiny", quietly = TRUE)) stop("Install optional package 'shiny'.")
  if (!is.numeric(max_points) || length(max_points) != 1L || is.na(max_points) ||
      max_points < 2L || max_points > 10000L || max_points != floor(max_points)) stop("History window must be 2..10000 points.")
  modes <- c(base = "Base R")
  if (requireNamespace("ggplot2", quietly = TRUE)) modes <- c(modes, ggplot = "ggplot2")
  if (requireNamespace("plotly", quietly = TRUE)) modes <- c(modes, plotly = "Plotly live")
  if (mode == "auto") mode <- if ("plotly" %in% names(modes)) "plotly" else if ("ggplot" %in% names(modes)) "ggplot" else "base"
  if (!mode %in% names(modes)) stop("Requested plot mode is unavailable: ", mode)
  source <- monitor_dashboard_source(path, transport, endpoint, snapshot_endpoint, max_points)
  receiver <- termr::termr_shiny_receiver(source, max_points = max_points, interval = interval,
    validate = monitor_snapshot_valid, close_source = TRUE)
  # One ordinary-frame conversion per receiver revision, shared by sessions.
  # Per-session plot work must not multiply the same history conversion.
  cached_key <- NULL; cached_frame <- NULL; frame_builds <- 0L
  shared_frame <- function() {
    state <- receiver$status()
    key <- list(state$source_id, state$sequence, state$generation)
    if (!identical(key, cached_key)) {
      cached_frame <<- termr::termr_stream_data(receiver, c("cpu", "ram"),
        max_points = max_points, extractor = monitor_extract)
      cached_key <<- key
      frame_builds <<- frame_builds + 1L
    }
    cached_frame
  }
  ready <- FALSE
  on.exit(if (!ready) receiver$close(), add = TRUE)
  ui <- shiny::fluidPage(
    shiny::titlePanel("termr live telemetry"),
    shiny::fluidRow(shiny::column(8, shiny::textOutput("connection")),
      shiny::column(4, shiny::radioButtons("view", "Chart mode", choices = stats::setNames(names(modes), unname(modes)), selected = mode, inline = TRUE))),
    shiny::textOutput("current"),
    shiny::sliderInput("window", "History window (points)", min = 2L, max = max_points,
      value = max_points, step = 1L),
    shiny::uiOutput("chart_ui"), shiny::textOutput("history_note"))
  server <- function(input, output, session) {
    selected <- shiny::reactive(if (is.null(input$view)) mode else input$view)
    latest <- termr::termr_shiny_reactive(receiver, session)
    history <- termr::termr_shiny_history(receiver, session, max_points = max_points)
    status <- termr::termr_shiny_status(receiver, session)
    frame <- shiny::reactive({
      history() # depend on the shared revision, not on chart/status timers
      count <- if (is.null(input$window)) max_points else min(max_points, max(2L, as.integer(input$window)))
      utils::tail(shared_frame(), count)
    })
    output$connection <- shiny::renderText({
      x <- status()
      time <- if (is.na(x$timestamp)) "never" else format(x$timestamp, tz = "UTC", usetz = TRUE)
      paste("Source:", x$state, "| reconnect:", x$reconnecting, "| gaps:", x$gaps,
        "| sequence:", x$sequence, "| updated:", time,
        if (!is.null(x$message)) paste("|", x$message) else "")
    })
    output$current <- shiny::renderText({
      x <- latest()
      paste("CPU:", monitor_format(x$metrics$cpu), "RAM:", monitor_format(x$metrics$ram),
        if (status()$state != "live") "(cached; source is not live)" else "")
    })
    output$history_note <- shiny::renderText(paste(nrow(frame()), "retained observations; gaps are not replayed."))
    output$chart_ui <- shiny::renderUI({
      if (selected() == "plotly") plotly::plotlyOutput("live", height = "520px")
      else shiny::tagList(shiny::plotOutput("cpu", height = "250px"), shiny::plotOutput("ram", height = "250px"))
    })
    base_chart <- function(field) {
      data <- frame()
      if (!nrow(data)) {graphics::plot.new(); graphics::title("Waiting for source"); return(invisible(NULL))}
      graphics::plot(data$timestamp, data[[field]], type = "n", ylim = c(0, 100), xlab = "Time (UTC)", ylab = toupper(field))
      for (segment in unique(data$segment)) {
        rows <- data$segment == segment
        graphics::lines(data$timestamp[rows], data[[field]][rows], type = "o", pch = 20)
      }
    }
    output$cpu <- shiny::renderPlot({if (selected() == "ggplot") print(monitor_ggplots(frame())$cpu) else base_chart("cpu")})
    output$ram <- shiny::renderPlot({if (selected() == "ggplot") print(monitor_ggplots(frame())$ram) else base_chart("ram")})
    if ("plotly" %in% names(modes)) {
      output$live <- plotly::renderPlotly(monitor_plotly_widget(probe))
      previous <- NULL; previous_window <- NULL; ready_id <- NULL
      waiting <- FALSE; ack_seen <- 0
      shiny::observe({
        if (is.null(input$live_ready) || selected() != "plotly") return(invisible(NULL))
        ack <- input$live_ack
        count <- if (is.list(ack) && identical(ack$ready, input$live_ready)) ack$count else 0
        if (!is.numeric(count) || length(count) != 1L || !is.finite(count)) count <- 0
        if (!identical(ready_id, input$live_ready)) {
          previous <<- NULL; waiting <<- FALSE; ack_seen <<- count
          ready_id <<- input$live_ready
        }
        # One update in flight per browser. While it renders, source history
        # keeps a bounded latest window; the next acknowledgement coalesces it.
        if (waiting && count <= ack_seen) return(invisible(NULL))
        waiting <<- FALSE; ack_seen <<- count
        data <- frame(); current_status <- status()
        if (!identical(previous_window, input$window)) previous <<- NULL
        plan <- monitor_plotly_plan(previous, data, current_status)
        limit <- if (is.null(input$window)) max_points else as.integer(input$window)
        monitor_plotly_send(session, "live", plan, limit)
        if (plan$type != "noop") {previous <<- plan; waiting <<- TRUE}
        previous_window <<- input$window
      })
    }
  }
  ready <- TRUE
  list(app = shiny::shinyApp(ui, server), receiver = receiver, close = receiver$close,
    diagnostics = function() c(receiver$diagnostics(), list(frame_builds = frame_builds)))
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  points <- as.integer(Sys.getenv("TERMR_HISTORY_POINTS", "600"))
  demo <- monitor_dashboard(if (length(args)) args[[1L]] else monitor_path(),
    if (length(args) > 1L) args[[2L]] else "auto", max_points = points,
    interval = as.integer(Sys.getenv("TERMR_DASHBOARD_POLL_MS", "500")))
  tryCatch(shiny::runApp(demo$app, host = "127.0.0.1", port = 3838L, launch.browser = FALSE), finally = demo$close())
}
