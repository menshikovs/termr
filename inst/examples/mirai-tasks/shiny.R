# Rscript shiny.R [direct|remote] [pub endpoint] [snapshot endpoint].
source_files <- Filter(Negate(is.null), lapply(sys.frames(), function(f) f$ofile))
local_file <- if (length(source_files)) tail(source_files, 1L)[[1L]] else sub("^--file=", "", grep("^--file=", commandArgs(), value = TRUE)[1L])
source(file.path(dirname(local_file), "common.R"), local = TRUE)

task_shiny <- function(mode = "direct", endpoint = "tcp://127.0.0.1:5581", snapshot_endpoint = "tcp://127.0.0.1:5582") {
  if (!requireNamespace("shiny", quietly = TRUE)) stop("Install optional shiny.")
  if (!mode %in% c("direct", "remote")) stop("Mode must be direct or remote.")
  if (mode == "direct" && utils::packageVersion("shiny") < "1.8.1") stop("Shiny >=1.8.1 is required for ExtendedTask.")
  pool <- if (mode == "direct") termr::termr_mirai_pool(2L, max_pending = 12L) else NULL
  remote <- if (mode == "remote") termr::termr_nano_connect(endpoint, "task.state", snapshot_endpoint, history = 100L) else NULL
  source <- if (mode == "direct") pool$events else remote
  receiver <- termr::termr_shiny_receiver(source, interval = 250L, max_points = 100L, close_source = mode == "remote")
  close <- function() {receiver$close(); if (!is.null(pool)) pool$close()}
  ready <- FALSE; on.exit(if (!ready) close(), add = TRUE)
  ui <- shiny::fluidPage(shiny::titlePanel(paste("mirai tasks —", mode)),
    shiny::textOutput("clock"), shiny::textOutput("connection"),
    if (mode == "direct") shiny::tagList(shiny::numericInput("chunks", "Chunks", 120, 1, 400),
      shiny::actionButton("submit", "Submit"), shiny::actionButton("cancel", "Cancel my task"), shiny::textOutput("result")),
    shiny::textOutput("counts"), shiny::tableOutput("tasks"),
    shiny::plotOutput("progress", height = "250px"), shiny::tableOutput("history"))
  server <- function(input, output, session) {
    latest <- termr::termr_shiny_reactive(receiver, session)
    history <- termr::termr_shiny_history(receiver, session, max_points = 100L)
    status <- termr::termr_shiny_status(receiver, session)
    owned <- list()
    if (mode == "direct") {
      computation <- shiny::withReactiveDomain(NULL, shiny::ExtendedTask$new(function(chunks) {
        # Inputs are snapshotted by invoke; no reactive reads in this function.
        task <- tryCatch(pool$submit(task_workload, args = list(chunks = chunks), progress = TRUE, timeout = 30), error = identity)
        if (inherits(task, "error")) return(promises::promise_resolve(list(status = "rejected", error = conditionMessage(task))))
        owned[[length(owned) + 1L]] <<- task
        owned <<- utils::tail(owned, 8L)
        promises::then(task$promise(),
          onFulfilled = function(value) list(status = "completed", value = value),
          onRejected = function(reason) list(status = task$status(), error = task$info()$error))
      }))
      shiny::observeEvent(input$submit, {
        if (computation$status() != "running") shiny::withReactiveDomain(NULL, computation$invoke(as.integer(input$chunks)))
      })
      shiny::observeEvent(input$cancel, for (task in owned) if (!task$ready()) task$cancel())
      output$result <- shiny::renderText({
        value <- computation$result()
        if (value$status == "completed") value$value else paste(value$status, value$error)
      })
      session$onSessionEnded(function() for (task in owned) if (!task$ready()) task$cancel())
    }
    snapshot <- shiny::reactive({
      latest(); history()
      if (mode == "remote") return(latest())
      rows <- lapply(owned, function(task) {
        value <- task$info()
        value$duration <- (if (is.null(value$finished_at)) as.numeric(Sys.time()) else value$finished_at) - value$submitted_at
        value
      })
      values <- vapply(rows, `[[`, "", "status")
      list(tasks = rows, counts = as.list(table(factor(values, levels = c("queued", "running", "completed", "failed", "cancelled", "timed_out")))),
        history = lapply(history(), `[[`, "payload"))
    })
    output$clock <- shiny::renderText({shiny::invalidateLater(100, session); paste("UI alive:", format(Sys.time(), "%H:%M:%OS1"))})
    output$connection <- shiny::renderText(paste("Event source:", status()$state,
      "— idle event streams may become stale; completed task results remain valid."))
    output$counts <- shiny::renderText({x <- snapshot(); if (is.null(x)) "Waiting for producer" else paste(names(x$counts), unlist(x$counts), collapse = " | ")})
    output$tasks <- shiny::renderTable(task_rows(snapshot()))
    output$progress <- shiny::renderPlot({
      rows <- task_rows(snapshot())
      if (!nrow(rows)) {graphics::plot.new(); graphics::title("Waiting for tasks"); return(invisible(NULL))}
      graphics::barplot(rows$progress, names.arg = seq_len(nrow(rows)), ylim = c(0, 1),
        ylab = "Reported fraction (missing = unknown)", xlab = "Retained task")
    })
    output$history <- shiny::renderTable({
      value <- snapshot(); records <- if (is.null(value)) list() else utils::tail(value$history, 12L)
      if (!length(records)) return(NULL)
      data.frame(event = vapply(records, `[[`, "", "event"),
        status = vapply(records, `[[`, "", "status"),
        error = vapply(records, function(x) if (is.null(x$error)) "" else substr(x$error, 1L, 120L), ""))
    })
  }
  ready <- TRUE
  list(app = shiny::shinyApp(ui, server), receiver = receiver, pool = pool, close = close)
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  demo <- task_shiny(if (length(args)) args[[1L]] else "direct",
    if (length(args) > 1L) args[[2L]] else "tcp://127.0.0.1:5581",
    if (length(args) > 2L) args[[3L]] else "tcp://127.0.0.1:5582")
  tryCatch(shiny::runApp(demo$app, host = "127.0.0.1", port = 3840L, launch.browser = FALSE), finally = demo$close())
}
