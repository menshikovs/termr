pkgload::load_all(".", quiet = TRUE)
ns <- asNamespace("termr")
internal <- function(name) get(name, envir = ns, inherits = FALSE)
observations <- list()
probe <- function(id, fn) {
  cat("\nPROBE", id, "\n")
  value <- tryCatch(fn(), error = function(e) list(harness_error = conditionMessage(e)))
  observations[[id]] <<- value
  dput(value)
}
error_text <- function(expr) tryCatch({ force(expr); NULL }, error = conditionMessage)

probe("grouped-key-dispatch", function() {
  pressed <- 0L
  focused <- 0L
  a <- app(vertical(input(id = "name"), button("Run", id = "run")),
    on("button.pressed", "#run", function(...) pressed <<- pressed + 1L))
  a$query_one("#run")$on("focus", function(...) focused <<- focused + 1L)
  p <- test_app(a)
  on.exit(p$stop())
  parser <- internal("KeyParser")$new()
  parsed <- parser$feed(charToRaw("Ada\t\r"))
  for (event in parsed) p$driver$feed(event)
  p$step()
  list(parsed = vapply(parsed, function(ev) ev$key, character(1)),
       text = a$query_one("#name")$value, focus = a$focused$id,
       focus_events = focused, presses = pressed)
})

probe("failed-source-switch", function() {
  t <- data_table(data.frame(x = 1:3))
  before <- t$row_data(1L)
  invalid <- table_source(function() NA_real_, "x", function(start, count, columns) data.frame(x = integer()))
  failure <- error_text(t$set_data(invalid))
  after_error <- error_text(t$row_data(1L))
  list(before = before, switch_error = failure, row_read_error = after_error,
       source_changed = identical(t$.__enclos_env__$private$.source, invalid))
})

probe("detached-ancestor-dispatch", function() {
  delivered <- 0L
  child <- button("Child")
  parent <- vertical(child)
  a <- app(parent)
  p <- test_app(a)
  on.exit(p$stop())
  child$on("audit.probe", function(...) parent$remove())
  parent$on("audit.probe", function(...) delivered <<- delivered + 1L)
  child$post_message("audit.probe")
  p$step()
  list(parent_detached = is.null(parent$app), detached_parent_deliveries = delivered)
})

probe("pilot-startup-error-cleanup", function() {
  state <- internal("termr_env")
  before <- length(state$apps)
  w <- label("failure")
  w$on("mount", function(...) stop("H1 mount error"))
  a <- app(w)
  failure <- error_text(test_app(a))
  private <- a$.__enclos_env__$private
  observation <- list(error = failure, running_after_error = private$.running,
    registered_app_delta = length(state$apps) - before,
    driver_retained = !is.null(private$.driver))
  private$shutdown()
  observation
})

probe("processx-control-bytes", function() {
  code <- "cat(intToUtf8(c(65L,100L,97L,9L,13L)))"
  child <- processx::process$new(file.path(R.home("bin"), if (.Platform$OS.type == "windows") "Rscript.exe" else "Rscript"),
    c("--vanilla", "-e", code), stdout = "|", stderr = "|", encoding = "UTF-8")
  on.exit(if (child$is_alive()) child$kill_tree())
  child$wait(10000L)
  list(exit = child$get_exit_status(), bytes = as.integer(charToRaw(child$read_output())))
})

probe("inkr-replacement-and-cache", function() {
  if (!requireNamespace("inkr", quietly = TRUE)) return(list(skipped = "inkr absent"))
  w <- button("Run")
  a <- app(w, inkr_stylesheet = "Button { color: red; }")
  old <- a$inkr_stylesheet
  replacement_error <- error_text(a$set_inkr_stylesheet("Button { color: #11223380; }"))
  render_error <- error_text(w$computed_style())
  private <- a$.__enclos_env__$private
  for (i in seq_len(4100L)) internal("inkr_store_style_cache")(private, paste0("probe-", i), list(style = NULL, explicit = logical()))
  list(replacement_error = replacement_error, previous_sheet_retained = identical(old, a$inkr_stylesheet),
    render_error = render_error, cache_entries = length(ls(private$.inkr_cache, all.names = TRUE)))
})

probe("strict-edit-input", function() {
  t <- data_table(data.frame(x = 1L), editable = TRUE)
  before <- t$row_data(1L)
  failure <- error_text(t$set_cell(1L, "x", "stop('must not execute')"))
  list(error = failure, unchanged = identical(before, t$row_data(1L)))
})

probe("edited-sort-pipeline-consistency", function() {
  original <- data.frame(x = 1:3)
  t <- data_table(original, editable = TRUE)
  t$sort("x")
  t$set_cell(1L, "x", "10")
  result <- t$reproducible_code("pipeline")
  actual_view <- t$data[t$view, , drop = FALSE]
  generated <- eval(parse(text = result$code), envir = list2env(list(data = t$data), parent = globalenv()))
  list(status = result$status, current_view = actual_view$x, generated_view = generated$x,
       matches = identical(actual_view, generated), source_input_unchanged = identical(original$x, 1:3))
})

probe("fractional-row-edit", function() {
  t <- data_table(data.frame(x = 1:3), editable = TRUE)
  failure <- error_text(t$set_cell(1.5, "x", "9"))
  list(error = failure, data = t$data$x)
})

probe("sustained-chart-backlog", function() {
  s <- termr_stream(history = 0L)
  chart <- line_chart(numeric(), numeric(), interactive = FALSE)
  p <- test_app(app(chart))
  on.exit({p$stop(); s$close()})
  chart$bind_stream(s, function(v) v$x, function(v) v$y, max_points = 100L)
  counter <- 0L
  emit <- function(n) for (i in seq_len(n)) {
    counter <<- counter + 1L
    s$emit(list(x = counter, y = counter))
  }
  emit(64L); p$step()
  for (i in seq_len(8L)) { emit(16L); p$advance(.001) }
  private <- chart$.__enclos_env__$private
  list(flushes = private$.stream_state$flush_count,
       pending = private$.stream_state$queue$size,
       processed_points = length(private$.stream_state$x),
       displayed_points = length(private$.spec$data$x),
       stream_subscribers = s$subscriber_count())
})

probe("source-projection-cache-key", function() {
  values <- data.frame(a = seq_len(200L), b = 201:400, check.names = FALSE)
  values[["a\rb"]] <- 401:600
  s <- table_source(nrow(values), names(values), function(start, count, columns) {
    values[seq.int(start, length.out = count), columns, drop = FALSE]
  })
  t <- data_table(s, row_names = FALSE)
  a <- app(t)
  t$set_column_visible("a\rb", FALSE)
  t$scroll_to_row(101L)
  first_error <- error_text(render_widget(a, 70L, 10L))
  t$set_column_visible("a\rb", TRUE)
  t$set_column_visible("a", FALSE)
  t$set_column_visible("b", FALSE)
  second_error <- error_text(render_widget(a, 70L, 10L))
  list(first_error = first_error, switched_projection_error = second_error)
})

probe("lubridate-specialized-support", function() {
  if (!requireNamespace("lubridate", quietly = TRUE)) return(list(skipped = "lubridate absent"))
  values <- list(Period = lubridate::period(month = 1L), Duration = lubridate::dseconds(1.25),
    Interval = lubridate::interval(as.POSIXct("2024-03-10", tz = "UTC"), as.POSIXct("2024-03-11", tz = "UTC")))
  lapply(values, function(value) {
    metadata <- internal("table_column_metadata")(value)
    code <- internal("termr_r_code")(internal("termr_r_value_ast")(value), packages = "lubridate")
    restored <- tryCatch(eval(parse(text = code), envir = new.env(parent = globalenv())), error = identity)
    list(isS4 = isS4(value), handler = internal("table_type_handler")(value)$id,
      editable = metadata$editable, code_support = internal("termr_r_value_support")(value)$ok,
      value_export_roundtrip = identical(value, restored))
  })
})

probe("owned-sql-editor-unmount", function() {
  if (!requireNamespace("DBI", quietly = TRUE) || !requireNamespace("RSQLite", quietly = TRUE)) return(list(skipped = "DBI/RSQLite absent"))
  con <- DBI::dbConnect(RSQLite::SQLite(), ":memory:")
  on.exit(if (DBI::dbIsValid(con)) DBI::dbDisconnect(con))
  editor <- sql_editor("SELECT 1", connection = db_connection(con, owned = TRUE))
  p <- test_app(app(editor))
  editor$remove()
  p$stop()
  list(owned_connection_still_valid_after_unmount_and_shutdown = DBI::dbIsValid(con))
})

probe("nonfinite-log-capacity", function() {
  a <- app(label("x"))
  warnings <- character()
  validation_error <- withCallingHandlers(error_text(a$log_events(size = Inf)), warning = function(w) {
    warnings <<- c(warnings, conditionMessage(w)); invokeRestart("muffleWarning")
  })
  startup_error <- error_text(test_app(a))
  list(validation_error = validation_error, warnings = warnings, startup_error = startup_error)
})

saveRDS(observations, paste0("audit-results/hardening/h1-architecture/probe-results-", .Platform$OS.type, ".rds"))
