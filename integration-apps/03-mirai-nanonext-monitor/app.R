monitor_work <- function(chunks = 12L, fail = FALSE, progress) {
  total <- 0
  for (i in seq_len(chunks)) {
    total <- total + sum(sqrt(seq_len(50000L) + i))
    progress(i / chunks, paste('chunk', i, 'of', chunks))
    if (fail && i == 2L) stop('Controlled Phase E task failure')
    Sys.sleep(.01)
  }
  list(sum = total, chunks = chunks)
}

distributed_model <- function(workers = 2L) {
  phase_e_require(c('mirai', 'nanonext', 'jsonlite'))
  pool <- termr::termr_mirai_pool(workers, max_pending = 8L, history = 128L, seed = 20261031L)
  ready <- FALSE
  on.exit(if (!ready) pool$close(), add = TRUE)
  metrics <- termr::termr_stream('phase.e.metrics', history = 128L)
  publisher <- termr::termr_nano_publish(metrics, 'tcp://127.0.0.1:0', 'tcp://127.0.0.1:0', heartbeat = .1)
  on.exit(if (!ready) {publisher$close(); metrics$close()}, add = TRUE)
  endpoint <- publisher$endpoint; snapshot_endpoint <- publisher$snapshot_endpoint
  connect <- function() termr::termr_nano_connect(endpoint, 'phase.e.metrics', snapshot_endpoint,
    history = 128L, buffer = 32L, resync_interval = .1, stale_after = .5)
  remote <- connect()
  on.exit(if (!ready) remote$close(), add = TRUE)
  state <- new.env(parent = emptyenv())
  state$closed <- FALSE; state$connected <- TRUE; state$sequence <- 0L
  state$events <- list(); state$tasks <- list(); state$started <- unname(proc.time()[['elapsed']])
  subscription <- pool$events$subscribe(function(event) {
    state$events <- utils::tail(c(state$events, list(event)), 128L)
    phase_e_mark('task-event', list(type = event$event, status = event$status))
  })
  rows <- function() {
    if (!length(state$tasks)) return(data.frame(task = character(), status = character(), progress = numeric(), error = character()))
    do.call(rbind, lapply(seq_along(state$tasks), function(i) {
      info <- state$tasks[[i]]$info()
      data.frame(task = paste(i, info$task_type), status = info$status,
        progress = if (is.null(info$progress)) NA_real_ else info$progress,
        error = if (is.null(info$error)) '' else substr(info$error, 1L, 128L))
    }))
  }
  submit <- function(fail = FALSE, slow = FALSE) {
    if (length(state$tasks) >= 24L) {
      finished <- which(vapply(state$tasks, function(task) task$ready(), TRUE))
      if (!length(finished)) stop('Retained task limit reached; wait or cancel.')
      state$tasks <- state$tasks[-finished[[1L]]]
    }
    task <- pool$submit(monitor_work, args = list(chunks = if (slow) 200L else 12L, fail = fail),
      progress = TRUE, task_type = if (fail) 'failure' else if (slow) 'long' else 'compute', timeout = 20)
    state$tasks[[length(state$tasks) + 1L]] <- task
    phase_e_mark('submit', list(kind = if (fail) 'failure' else if (slow) 'long' else 'compute'))
    invisible(task)
  }
  poll <- function(emit = TRUE) {
    if (state$closed) return(invisible())
    pool$poll()
    if (emit) {
      state$sequence <- state$sequence + 1L
      diag <- pool$diagnostics()
      elapsed <- max(.001, unname(proc.time()[['elapsed']]) - state$started)
      metrics$emit(list(timestamp = as.numeric(Sys.time()), sequence = state$sequence,
        pending = diag$pending, completed = diag$counters$completed,
        throughput = diag$counters$completed / elapsed))
    }
    if (state$connected) publisher$poll()
    remote$poll()
    invisible(remote$latest())
  }
  cancel <- function(index = NULL) {
    active <- which(!vapply(state$tasks, function(task) task$ready(), TRUE))
    selected <- if (is.null(index)) utils::head(active, 1L) else index
    if (length(selected) && selected %in% active) state$tasks[[selected]]$cancel()
    phase_e_mark('cancel')
    invisible()
  }
  disconnect <- function() {
    if (state$connected) publisher$close()
    state$connected <- FALSE
    phase_e_mark('disconnect')
  }
  reconnect <- function() {
    remote$close()
    if (!state$connected) publisher <<- termr::termr_nano_publish(metrics, endpoint, snapshot_endpoint, heartbeat = .1)
    state$connected <- TRUE; remote <<- connect()
    phase_e_mark('reconnect')
    invisible(remote)
  }
  close <- function() {
    if (state$closed) return(invisible())
    state$closed <- TRUE
    subscription$unsubscribe(); remote$close(); publisher$close(); metrics$close(); pool$close()
  }
  ready <- TRUE
  list(pool = pool, metrics = metrics, remote = function() remote, rows = rows,
    state = state, submit = submit, cancel = cancel, poll = poll, disconnect = disconnect,
    reconnect = reconnect, close = close,
    diagnostics = function() list(closed = state$closed, pool = pool$diagnostics(),
      transport = remote$status(), retained_events = length(state$events),
      subscriptions = pool$events$subscriber_count()))
}

distributed_monitor <- function(workers = 2L) {
  model <- distributed_model(workers)
  ready <- FALSE; on.exit(if (!ready) model$close(), add = TRUE)
  table <- termr::data_table(model$rows(), id = 'tasks', header_sort = TRUE)
  chart <- termr::line_chart(numeric(), numeric(), id = 'task-chart', title = 'Pending jobs via nanonext')
  bind_chart <- function() chart$bind_stream(model$remote(), function(x) x$sequence,
    function(x) x$pending, max_points = 128L)
  bind_chart()
  counts <- termr::label('', id = 'counts', style = termr::style(height = 2))
  details <- termr::label('Select a task; Enter opens details', id = 'details', style = termr::style(height = 2))
  history <- termr::label('', id = 'messages', style = termr::style(height = 3))
  progress <- termr::progress_bar(NA_real_, id = 'progress')
  last_rows <- NULL
  refresh <- function() {
    model$poll()
    rows <- model$rows()
    if (!identical(rows, last_rows)) {
      position <- table$cursor_row
      table$set_data(rows)
      if (nrow(rows) && position > 0L) table$move_cursor(row = min(position, nrow(rows)))
      last_rows <<- rows
    }
    diag <- model$diagnostics()
    counts$update(paste('Workers:', diag$pool$workers, '| pending jobs:', diag$pool$pending,
      '| transport:', diag$transport$state, '| AIO:', diag$transport$pending,
      '| completed:', diag$pool$counters$completed,
      '\nThroughput:', round(model$metrics$latest()$throughput, 2), 'jobs/s | bounded history:', diag$retained_events))
    if (nrow(rows)) progress$set(value = utils::tail(rows$progress, 1L))
    recent <- utils::tail(model$state$events, 3L)
    history$update(paste(vapply(recent, function(e) paste(e$event, e$status), ''), collapse = '\n'))
    phase_e_mark('monitor', list(pending = diag$pool$pending, completed = diag$pool$counters$completed,
      failed = diag$pool$counters$failed, connection = diag$transport$state,
      transport_sequence = diag$transport$sequence))
  }
  safe <- function(fn) function(app) tryCatch({fn(app); refresh()}, error = function(e) {
    app$notify(conditionMessage(e), severity = 'warning'); phase_e_mark('rejected', list(message = conditionMessage(e)))
  })
  actions <- list(
    submit = safe(function(app) model$submit()),
    slow = safe(function(app) model$submit(slow = TRUE)),
    fail = safe(function(app) model$submit(fail = TRUE)),
    cancel = safe(function(app) model$cancel()),
    refresh = safe(function(app) invisible()),
    disconnect = safe(function(app) model$disconnect()),
    reconnect = safe(function(app) {chart$unbind_stream(); model$reconnect(); bind_chart()}),
    details = safe(function(app) {
      row_index <- table$selected_row()
      if (!is.na(row_index)) {
        row <- table$row_data(row_index)
        index <- match(row$task, model$rows()$task)
        if (is.na(index)) stop('Selected task is no longer retained.')
        task <- model$state$tasks[[index]]
        info <- task$info()
        result <- if (info$status == 'completed') capture.output(str(task$result(), max.level = 2L)) else character()
        text <- paste(c(paste('Task:', row$task), paste('Status:', info$status),
          result, if (!is.null(info$error)) paste('Error:', info$error)), collapse = '\n')
        app$push_screen(termr::alert_dialog(text, title = 'Task details'))
        phase_e_mark('task-details', list(status = info$status, result = if (info$status == 'completed') task$result() else NULL))
      }
    }))
  buttons <- lapply(names(actions), function(name) termr::button(name, id = paste0('task-', name)))
  view <- termr::app(termr::vertical(
    termr::label('Distributed Task & Stream Monitor', id = 'monitor-heading'),
    termr::label('n submit | l long | e fail | c cancel | d disconnect | r reconnect | q quit'),
    termr::tabs(termr::tab('Tasks', table), termr::tab('Stream', chart),
      termr::tab('Actions', termr::scroll_view(termr::vertical(buttons))), id = 'monitor-tabs'),
    progress, counts, history, details),
    termr::bind('q', 'quit'),
    termr::on('button.pressed', function(event, app) {
      action <- sub('^task-', '', event$sender$id)
      if (action %in% names(actions)) actions[[action]](app)
    }))
  for (pair in list(c('n', 'submit'), c('l', 'slow'), c('e', 'fail'), c('c', 'cancel'),
    c('d', 'disconnect'), c('r', 'reconnect'), c('f5', 'refresh'))) local({
      key <- pair[[1L]]; action <- pair[[2L]]; view$bind(key, actions[[action]])
    })
  view$on('datatable.row_selected', '#tasks', function(event, app) details$update(paste(unlist(event$data$value), collapse = ' | ')))
  view$on('datatable.row_activated', '#tasks', function(event, app) actions$details(app))
  view$on('mount', '#monitor-heading', function(event, app) {
    refresh()
    phase_e_mark('ready', list(app = 'monitor'))
    if (nzchar(Sys.getenv('TERMR_E_EVENTS',''))) {
      children <- ps::ps_children(ps::ps_handle(), recursive = TRUE)
      phase_e_mark('owned-processes', list(processes = lapply(children, function(handle)
        list(pid = ps::ps_pid(handle), created = as.numeric(ps::ps_create_time(handle))))))
    }
    table$focus()
  })
  view$set_interval(.05, function(app) refresh())
  ready <- TRUE
  list(app = view, model = model, table = table, chart = chart, refresh = refresh,
    close = function() {chart$unbind_stream(); model$close()},
    summary = function() list(app = 'monitor', closed = model$state$closed,
      pool_closed = model$pool$is_closed(), transport_closed = model$remote()$is_closed(),
      source_closed = model$metrics$is_closed(),
      retained = length(model$state$tasks), subscriptions = model$pool$events$subscriber_count()))
}
