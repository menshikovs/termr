workbench_fixtures <- function() {
  cars <- data.frame(name = rownames(datasets::mtcars), value = datasets::mtcars$mpg,
    cylinders = datasets::mtcars$cyl, weight = datasets::mtcars$wt)
  flowers <- data.frame(name = paste('Iris', seq_len(nrow(datasets::iris))),
    value = datasets::iris$Sepal.Length, species = datasets::iris$Species,
    width = datasets::iris$Sepal.Width)
  typed <- data.frame(name = c('Alpha', 'Бета', '東京', 'Delta', 'Echo', 'Foxtrot'),
    value = c(1, 2.5, NA, NaN, Inf, -3),
    date = as.Date('2026-01-01') + 0:5,
    instant = as.POSIXct('2026-01-01', tz = 'UTC') + (0:5) / 4,
    group = factor(c('a', 'b', 'a', NA, 'b', 'a')))
  if (requireNamespace('bit64', quietly = TRUE)) typed$id64 <- bit64::as.integer64(c('9007199254740993', '2', NA, '4', '5', '6'))
  if (requireNamespace('units', quietly = TRUE)) typed$distance <- units::set_units(1:6, 'm', mode = 'standard')
  if (requireNamespace('haven', quietly = TRUE)) typed$labelled <- haven::labelled(c(1, 2, haven::tagged_na('a'), NA, 1, 2), c(Yes = 1, No = 2), label = 'Response')
  typed$custom <- structure(1:6, class = 'workbench_score', calibration = 'fixture')
  if (requireNamespace('vctrs', quietly = TRUE)) typed$vector <- vctrs::new_vctr(as.double(1:6), class = 'workbench_vctr')
  list(cars = cars, iris = flowers, typed = typed)
}

workbench_app <- function(use_inkr = requireNamespace('inkr', quietly = TRUE), chart_mode = 'auto') {
  fixtures <- workbench_fixtures()
  state <- new.env(parent = emptyenv())
  state$dataset <- 'cars'; state$lazy <- FALSE; state$theme <- 'dark'
  state$ticks <- 0L; state$closed <- FALSE; state$last_code <- NULL
  state$original <- fixtures$cars
  stream <- termr::termr_stream('workbench.metrics', history = 64L)
  table <- termr::data_table(state$original, id = 'data', editable = TRUE,
    show_types = TRUE, zebra = TRUE, header_sort = TRUE)
  types <- termr::data_table(table$column_info()[c('name', 'type', 'class', 'editable')], id = 'types')
  status <- termr::label('Ready: local cars', id = 'status', style = termr::style(height = 2))
  query <- termr::input('20', id = 'filter-value', placeholder = 'Minimum value')
  search <- termr::input('Merc', id = 'find-text', placeholder = 'Find text')
  edit <- termr::input('12.5', id = 'edit-value', placeholder = 'New row-1 value')
  line <- termr::line_chart(numeric(), numeric(), id = 'live-chart', mode = chart_mode)
  line$bind_stream(stream, function(x) x$sequence, function(x) x$value, max_points = 64L)
  scatter <- termr::scatter_chart(1:32, fixtures$cars$value, mode = chart_mode, id = 'scatter', title = 'Dataset values')
  bars <- termr::bar_chart(fixtures$cars$name[1:8], fixtures$cars$value[1:8], mode = chart_mode, id = 'bar')
  histogram <- termr::histogram(fixtures$cars$value, mode = chart_mode, id = 'histogram')
  heatmap <- termr::heatmap_chart(matrix(rep(fixtures$cars$value, length.out = 36L), 6), mode = chart_mode, id = 'heatmap')
  refresh_charts <- function() {
    value <- state$original$value[is.finite(state$original$value)]
    scatter$update_data(x = seq_along(value), y = value)
    count <- min(8L, length(value))
    bars$update_data(labels = paste('Row', seq_len(count)), values = value[seq_len(count)])
    histogram$update_data(x = value)
    heatmap$update_data(z = matrix(if (length(value)) rep(value, length.out = 36L) else NA_real_, 6L, 6L))
  }
  chart_tabs <- termr::tabs(
    termr::tab('Line', line),
    termr::tab('Scatter', scatter), termr::tab('Bar', bars),
    termr::tab('Histogram', histogram), termr::tab('Heatmap', heatmap),
    id = 'chart-tabs')
  pages <- termr::tabs(termr::tab('Data', table), termr::tab('Charts', chart_tabs),
    termr::tab('Types', types), termr::tab('Help', termr::label(
      'F2 dataset | F11 / Alt+S local/lazy | F4 theme | F5 filter\nF6 edit cell | F7 select | F8 R value | F9 R pipeline\nF10 sample | F12 / Alt+C charts | Alt+T types | Esc data\nDataset plots use finite unfiltered values; line is an independent bounded stream.\nUnknown/custom types remain read-only; export reports its limits.', wrap = 'word')),
    id = 'pages')
  sidebar <- termr::scroll_view(termr::vertical(
    termr::label('DATA WORKBENCH', style = termr::style(bold = TRUE)),
    termr::button('Dataset [F2]', id = 'dataset'), termr::button('Local/lazy [F11]', id = 'source'),
    query, termr::button('Filter [F5]', id = 'filter'), termr::button('Reset view', id = 'reset'),
    search, termr::button('Find', id = 'find'), termr::button('Sort value', id = 'sort'),
    termr::button('Select 3 [F7]', id = 'select'), edit,
    termr::button('Apply local value', id = 'apply-edit'), termr::button('Edit cell [F6]', id = 'edit'),
    termr::button('Copy R value [F8]', id = 'copy-value'), termr::button('Copy pipeline [F9]', id = 'copy-pipeline'),
    termr::button('Theme [F4]', id = 'theme'), termr::button('Chart sample [F10]', id = 'sample'),
    termr::button('Confirm reset', id = 'confirm-reset'), termr::button('Quit', id = 'quit')),
    id = 'sidebar', style = termr::style(width = 25, height = '1fr'))
  notify <- function(message) {
    status$update(message)
    phase_e_mark('status', list(message = message))
    invisible(message)
  }
  refresh_types <- function() types$set_data(table$column_info()[c('name', 'type', 'class', 'editable')])
  load_data <- function() {
    state$original <- fixtures[[state$dataset]]
    value <- state$original
    if (state$lazy) {
      base <- fixtures$cars
      value <- termr::table_source(10000L, names(base), function(start, count, columns = NULL) {
        result <- base[((seq.int(start, length.out = count) - 1L) %% nrow(base)) + 1L, , drop = FALSE]
        rownames(result) <- NULL
        if (!is.null(columns)) result <- result[columns]
        result
      })
    }
    table$set_data(value); refresh_types(); refresh_charts()
    notify(paste(state$dataset, if (state$lazy) 'lazy/read-only 10000 rows' else 'local/editable columns only'))
    phase_e_mark('source', list(dataset = state$dataset, lazy = state$lazy, rows = table$row_count))
  }
  theme <- function(app) {
    state$theme <- if (state$theme == 'dark') 'light' else 'dark'
    if (use_inkr) app$set_inkr_stylesheet(file.path(phase_e_root, 'integration-apps/01-termr-showcase', paste0(state$theme, '.inkr')))
    else app$theme <- termr::termr_theme(if (state$theme == 'dark') 'dark' else 'light')
    notify(paste('Theme:', state$theme, if (use_inkr) '(inkr)' else '(termr fallback)'))
    phase_e_mark('theme', list(theme = state$theme))
  }
  sample <- function() {
    state$ticks <- state$ticks + 1L
    stream$emit(list(sequence = state$ticks, value = 10 + sin(state$ticks / 4)))
    phase_e_mark('sample', list(sequence = state$ticks))
  }
  copy_code <- function(app, kind) {
    state$last_code <- table$reproducible_code(kind)
    result <- state$last_code
    if (is.null(result$code)) stop(result$reason)
    app$clipboard_write(result$code, system = FALSE)
    notify(paste('R', kind, result$status))
    app$push_screen(termr::alert_dialog(paste(result$status, result$code, sep = '\n'), title = 'Copy as R', width = 64))
    phase_e_mark('copy', list(kind = kind, status = result$status))
  }
  actions <- list(
    dataset = function(app) {keys <- names(fixtures); state$dataset <- keys[(match(state$dataset, keys) %% length(keys)) + 1L]; state$lazy <- FALSE; load_data()},
    source = function(app) {state$lazy <- !state$lazy; if (state$lazy) state$dataset <- 'cars'; load_data()},
    theme = theme, sample = function(app) sample(),
    filter = function(app) {
      minimum <- suppressWarnings(as.numeric(query$value))
      if (length(minimum) != 1L || !is.finite(minimum)) stop('Enter one finite minimum value.')
      table$filter_columns(list(value = termr::table_filter('range', min = minimum, max = .Machine$double.xmax)))
      notify(paste('Filtered:', table$row_count, 'rows')); phase_e_mark('filter', list(rows = table$row_count))
    },
    reset = function(app) {load_data(); notify('View reset')},
    find = function(app) {table$find(search$value); table$focus(); phase_e_mark('find', list(query = search$value))},
    sort = function(app) {table$sort('value', decreasing = TRUE); phase_e_mark('sort')},
    select = function(app) {if (table$row_count) table$select_range(1L, min(3L, table$row_count)); phase_e_mark('select')},
    `apply-edit` = function(app) {table$set_cell(1L, 'value', edit$value); notify('Local cell edited'); phase_e_mark('edit', list(value = edit$value))},
    edit = function(app) table$edit_cell(1L, 'value'),
    `copy-value` = function(app) copy_code(app, 'value'),
    `copy-pipeline` = function(app) copy_code(app, 'pipeline'),
    `confirm-reset` = function(app) app$push_screen(termr::confirm_dialog('Discard local view edits?', on_confirm = function(app) load_data())),
    quit = function(app) app$exit()
  )
  dispatch <- function(name, app) tryCatch(actions[[name]](app), error = function(e) {
    notify(paste('Rejected:', conditionMessage(e))); app$notify(conditionMessage(e), severity = 'warning')
    phase_e_mark('rejected', list(action = name, message = conditionMessage(e)))
  })
  view <- termr::app(termr::vertical(
    termr::label('Termr Data Workbench', id = 'heading', classes = 'heading', style = termr::style(height = 1)),
    termr::horizontal(sidebar, pages, style = termr::style(height = '1fr')),
    status, termr::label('F2 data  F11 source  F4 theme  F12 charts  q quit', id = 'footer')),
    title = 'Termr Data Workbench',
    stylesheet = termr::stylesheet('#heading { bold: true; }'),
    inkr_stylesheet = if (use_inkr) file.path(phase_e_root, 'integration-apps/01-termr-showcase/dark.inkr') else NULL,
    termr::on('button.pressed', function(event, app) if (event$sender$id %in% names(actions)) dispatch(event$sender$id, app)),
    termr::bind('q', 'quit'), termr::bind('escape', function(app) {pages$activate(1L); table$focus()}),
    termr::bind('alt+c', function(app) {pages$activate(2L); line$focus()}),
    termr::bind('f12', function(app) {pages$activate(2L); line$focus()}),
    termr::bind('alt+t', function(app) pages$activate(3L)))
  for (pair in list(c('f2', 'dataset'), c('alt+s', 'source'), c('f4', 'theme'), c('f5', 'filter'),
    c('f6', 'edit'), c('f7', 'select'), c('f8', 'copy-value'), c('f9', 'copy-pipeline'), c('f10', 'sample'))) {
    local({key <- pair[[1L]]; action <- pair[[2L]]; view$bind(key, function(app) dispatch(action, app))})
  }
  view$bind('f11', function(app) dispatch('source', app))
  resize <- function(app) sidebar$set(visible = app$size[['width']] >= 70L)
  view$on('resize', handler = function(event, app) resize(app))
  view$on('termrcharts.line.selected', '#live-chart', function(event, app) {
    notify(paste('Selected stream point', event$data$index))
    phase_e_mark('chart-selection', list(index = event$data$index))
  })
  view$on('datatable.cell_changed', '#data', function(event, app) {
    phase_e_mark('cell-changed', list(row = event$data$row, column = event$data$column, value = event$data$value))
  })
  view$on('tabs.changed', '#chart-tabs', function(event, app) {
    phase_e_mark('chart-tab', list(index = event$data$index))
  })
  view$on('key', handler = function(event, app) phase_e_mark('key', list(key = event$key)))
  view$on('mount', '#heading', function(event, app) {resize(app); phase_e_mark('ready', list(app = 'showcase')); table$focus()})
  view$set_interval(.5, function(app) sample())
  sample()
  list(app = view, table = table, types = types, stream = stream, fixtures = fixtures,
    state = state, action = function(name) dispatch(name, view),
    close = function() {if (!state$closed) {stream$close(); state$closed <- TRUE}},
    summary = function() list(app = 'showcase', dataset = state$dataset, rows = table$row_count,
      samples = state$ticks, subscribers = stream$subscriber_count(), closed = state$closed))
}
