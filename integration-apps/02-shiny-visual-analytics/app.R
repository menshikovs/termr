analytics_model <- function() {
  stream <- termr::termr_stream('analytics.metrics', history = 120L)
  state <- new.env(parent = emptyenv())
  state$source <- 'alpha'; state$sequence <- 0L; state$ticks <- 0L
  state$empty <- FALSE; state$closed <- FALSE
  advance <- function(invalid = FALSE) {
    if (state$closed) stop('Analytics source is closed.')
    state$sequence <- state$sequence + 1L; state$ticks <- state$ticks + 1L
    offset <- if (state$source == 'alpha') 0 else 10
    stream$emit(list(source_id = state$source, sequence = state$sequence,
      timestamp = as.numeric(Sys.time()),
      cpu = if (invalid) NaN else 40 + offset + 12 * sin(state$sequence / 3),
      ram = if (invalid) NA_real_ else 55 + offset + 4 * cos(state$sequence / 5),
      empty = state$empty, label = if (state$source == 'alpha') 'Метрικές 東京' else 'Beta'))
    invisible(stream$latest())
  }
  frame <- function() {
    data <- termr::termr_stream_data(stream, c('cpu', 'ram'), max_points = 120L)
    if (state$empty) data <- data[0, , drop = FALSE]
    data
  }
  change <- function() {state$source <- if (state$source == 'alpha') 'beta' else 'alpha'; state$sequence <- 0L; state$empty <- FALSE; advance()}
  empty <- function() {state$empty <- !state$empty; advance()}
  advance()
  list(stream = stream, state = state, advance = advance, frame = frame, change = change, empty = empty,
    close = function() {if (!state$closed) {stream$close(); state$closed <- TRUE}})
}

analytics_terminal <- function(model = analytics_model()) {
  table <- termr::data_table(model$frame()[c('timestamp', 'cpu', 'ram', 'sequence')], show_types = TRUE, id = 'analytics-data')
  chart <- termr::line_chart(numeric(), numeric(), mode = 'auto', id = 'analytics-chart')
  bind_chart <- function() chart$bind_stream(model$stream, function(x) x$sequence,
    function(x) if (!isTRUE(x$empty) && is.finite(x$cpu)) x$cpu else NA_real_, max_points = 120L)
  bind_chart()
  chart_empty <- FALSE
  status <- termr::label('', id = 'analytics-status')
  refresh <- function() {
    table$set_data(model$frame()[c('timestamp', 'cpu', 'ram', 'sequence')])
    if (model$state$empty && !chart_empty) {
      chart$unbind_stream()
      chart$update_data(x = numeric(), y = numeric())
    } else if (!model$state$empty && chart_empty) bind_chart()
    chart_empty <<- model$state$empty
    status$update(paste('Source', model$state$source, 'sequence', model$state$sequence,
      if (model$state$empty) 'EMPTY' else 'live', '| Метрικές 東京'))
    phase_e_mark('analytics', list(source = model$state$source, sequence = model$state$sequence,
      rows = table$row_count, empty = model$state$empty))
  }
  view <- termr::app(termr::vertical(
    termr::label('Shiny Visual Analytics Bridge', id = 'analytics-heading'),
    termr::label('F2 sample | F11 source (Alt+S) | F4 empty | F5 NA/NaN | q quit'),
    table, chart, status),
    termr::bind('f2', function(app) {model$advance(); refresh()}),
    termr::bind('alt+s', function(app) {model$change(); refresh()}),
    termr::bind('f11', function(app) {model$change(); refresh()}),
    termr::bind('f4', function(app) {model$empty(); refresh()}),
    termr::bind('f5', function(app) {model$advance(TRUE); refresh()}),
    termr::bind('q', 'quit'))
  view$on('mount', '#analytics-heading', function(event, app) {refresh(); phase_e_mark('ready', list(app = 'analytics'))})
  list(app = view, model = model, table = table, chart = chart,
    close = function() {chart$unbind_stream(); model$close()},
    summary = function() list(app = 'analytics', source = model$state$source,
      sequence = model$state$sequence, rows = table$row_count, closed = model$state$closed))
}

analytics_dashboard <- function(model = analytics_model(), interval = 500L) {
  phase_e_require(c('shiny', 'ggplot2', 'plotly', 'htmlwidgets'))
  # Reuse the existing example's bounded proxy/ready/ack implementation.
  helpers <- new.env(parent = environment())
  source(file.path(phase_e_root, 'inst/examples/system-monitor-live/visualization.R'), local = helpers, encoding = 'UTF-8')
  receiver <- termr::termr_shiny_receiver(model$stream, max_points = 120L, interval = interval)
  state <- new.env(parent = emptyenv())
  state$closed <- FALSE; state$frames <- 0L; state$widgets <- 0L; state$auto <- FALSE
  producer <- shiny::observe({
    shiny::invalidateLater(interval)
    if (state$auto && receiver$diagnostics()$sessions > 0L) model$advance()
  }, domain = NULL)
  ui <- shiny::fluidPage(
    shiny::tags$head(shiny::tags$link(rel = 'icon', href = 'data:,')),
    shiny::titlePanel('Shiny Visual Analytics Bridge'),
    shiny::p('Read-only termr snapshot. Browser controls change demonstration data, never a running TUI.'),
    shiny::fluidRow(shiny::column(12,
      shiny::actionButton('next_sample', 'Next sample'), shiny::actionButton('source', 'Switch source'),
      shiny::actionButton('empty', 'Toggle empty'), shiny::actionButton('invalid', 'NA / NaN sample'),
      shiny::checkboxInput('auto', 'Automatic samples', FALSE))),
    shiny::textOutput('source_status'), shiny::textOutput('agreement'),
    shiny::fluidRow(shiny::column(6, shiny::plotOutput('ggplot', height = '260px')),
      shiny::column(6, plotly::plotlyOutput('live', height = '320px'))),
    shiny::tableOutput('values'), shiny::h4('termr read-only snapshot'), shiny::verbatimTextOutput('terminal'))
  server <- function(input, output, session) {
    latest <- termr::termr_shiny_reactive(receiver, session)
    history <- termr::termr_shiny_history(receiver, session, max_points = 120L)
    status <- termr::termr_shiny_status(receiver, session)
    frame <- shiny::reactive({
      history(); value <- latest()
      data <- termr::termr_stream_data(receiver, c('cpu', 'ram'), max_points = 120L)
      if (isTRUE(value$empty)) data <- data[0, , drop = FALSE]
      state$frames <- state$frames + 1L
      phase_e_mark('web-frame', list(rows = nrow(data), source = value$source_id,
        sequence = value$sequence, cpu = if (nrow(data)) utils::tail(data$cpu, 1L) else NULL))
      data
    })
    shiny::observeEvent(input$next_sample, {model$advance(); receiver$poll()})
    shiny::observeEvent(input$source, {model$change(); receiver$poll()})
    shiny::observeEvent(input$empty, {model$empty(); receiver$poll()})
    shiny::observeEvent(input$invalid, {model$advance(TRUE); receiver$poll()})
    shiny::observeEvent(input$auto, {state$auto <- isTRUE(input$auto)})
    output$source_status <- shiny::renderText({
      value <- latest(); s <- status()
      paste('Source:', value$source_id, '| sequence:', value$sequence, '|', s$state,
        '| updated:', format(as.POSIXct(value$timestamp, origin = '1970-01-01', tz = 'UTC'), tz = 'UTC'),
        '|', value$label, if (isTRUE(value$empty)) '| EMPTY' else '')
    })
    output$agreement <- shiny::renderText(paste(nrow(frame()), 'rows shared by ggplot2, Plotly and termr'))
    output$values <- shiny::renderTable(utils::tail(frame()[c('timestamp', 'cpu', 'ram', 'sequence')], 8L))
    output$terminal <- shiny::renderText(termr::render_text(
      termr::data_table(utils::tail(frame()[c('cpu', 'ram', 'sequence')], 8L), show_types = TRUE), width = 62L, height = 10L))
    output$ggplot <- shiny::renderPlot({
      data <- frame()
      ggplot2::ggplot(data, ggplot2::aes(timestamp, cpu, group = segment)) +
        (if (nrow(data) > 1L) ggplot2::geom_line(na.rm = TRUE) else NULL) + ggplot2::geom_point(na.rm = TRUE) +
        ggplot2::labs(title = 'CPU | shared numeric data', x = 'UTC', y = 'CPU') + ggplot2::theme_minimal()
    })
    output$live <- plotly::renderPlotly({state$widgets <- state$widgets + 1L; helpers$monitor_plotly_widget(FALSE)})
    previous <- NULL; ready_id <- NULL; waiting <- FALSE; ack_seen <- 0
    shiny::observe({
      if (is.null(input$live_ready)) return(invisible(NULL))
      ack <- input$live_ack
      count <- if (is.list(ack) && identical(ack$ready, input$live_ready)) ack$count else 0
      if (!is.numeric(count) || length(count) != 1L || !is.finite(count)) count <- 0
      if (!identical(ready_id, input$live_ready)) {previous <<- NULL; waiting <<- FALSE; ready_id <<- input$live_ready; ack_seen <<- count}
      if (waiting && count <= ack_seen) return(invisible(NULL))
      waiting <<- FALSE; ack_seen <<- count
      plan <- helpers$monitor_plotly_plan(previous, frame(), status())
      helpers$monitor_plotly_send(session, 'live', plan, 120L)
      if (plan$type != 'noop') {previous <<- plan; waiting <<- TRUE}
    })
    # Expose read-only reactive functions to testServer, not remote TUI controls.
    session$userData$frame <- frame
    session$userData$status <- status
  }
  close <- function() {
    if (state$closed) return(invisible())
    state$closed <- TRUE; producer$destroy(); receiver$close(); model$close()
  }
  list(app = shiny::shinyApp(ui, server), server = server, model = model, receiver = receiver,
    close = close, diagnostics = function() c(receiver$diagnostics(),
      list(frame_builds = state$frames, widget_builds = state$widgets, producer_observers = if (state$closed) 0L else 1L)))
}
