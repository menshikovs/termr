# Linux only. --library=baseline|candidate --mode=headless|terminal --fixtures=true|false
args <- commandArgs(TRUE)
option <- function(name, default) {
  value <- grep(paste0('^--', name, '='), args, value = TRUE)
  if (length(value)) sub(paste0('^--', name, '='), '', value[[1L]]) else default
}
root <- normalizePath(Sys.getenv('TERMR_PROJECT_ROOT', getwd()), winslash = '/')
library_kind <- match.arg(option('library', 'candidate'), c('baseline', 'candidate'))
mode <- match.arg(option('mode', 'terminal'), c('headless', 'terminal'))
if (Sys.info()[['sysname']] != 'Linux') stop('rtop requires Linux /proc; use Ubuntu WSL.', call. = FALSE)
lib <- file.path(root, 'integration-apps/.deps', if (library_kind == 'baseline') 'baseline-linux' else 'R-linux')
.libPaths(c(lib, .libPaths()))
library(termr)
upstream <- file.path(root, 'integration-apps/legacy-rtop/upstream')
env <- new.env(parent = .GlobalEnv)
modules <- c('platform.R', 'format.R', 'collectors.R', 'collectors/cpu.R', 'collectors/memory.R',
  'collectors/network.R', 'collectors/disk.R', 'collectors/processes.R', 'state.R',
  'widgets/history.R', 'widgets/cpu.R', 'widgets/memory.R', 'widgets/network.R', 'widgets/disk.R',
  'widgets/processes.R', 'widgets.R', 'app.R')
for (module in modules) sys.source(file.path(upstream, 'R', module), envir = env)
env$check_platform()
version <- as.character(packageVersion('termr'))
if (!version %in% c('1.0.1', if (library_kind == 'candidate') '2.0.0')) stop('Legacy test version gate rejected ', version)
if (identical(option('fixtures', 'true'), 'true')) {
  sys.source(file.path(root, 'integration-apps/legacy-rtop/fixtures.R'), envir = .GlobalEnv)
  rtop_fixture_collectors(env, upstream)
}
mark <- function(event, data = list()) {
  path <- Sys.getenv('TERMR_E_EVENTS', '')
  if (nzchar(path)) cat(jsonlite::toJSON(c(list(event = event), data), auto_unbox = TRUE), '\n', file = path, append = TRUE)
}
original_run <- termr::run
runner <- function(application, ...) {
  application$on('mount', '#process-table', function(event, app) mark('rtop-ready', list(rows = app$query_one('#process-table')$row_count)))
  application$on('resize', handler = function(event, app) mark('resize', list(width = event$width, height = event$height)))
  application$on('input.changed', '#search', function(event, app) mark('filter', list(value = event$data$value)))
  application$on('datatable.row_selected', '#process-table', function(event, app) mark('selection', list(pid = event$data$value$PID)))
  if (mode == 'terminal') {
    on.exit(mark('stopped'), add = TRUE)
    return(original_run(application, ...))
  }
  p <- termr::test_app(application, width = 100L, height = 32L)
  on.exit(p$stop(), add = TRUE)
  results <- list()
  snapshot <- function(name) {
    text <- gsub('[0-9]{2}:[0-9]{2}:[0-9]{2}', '<CLOCK>', p$screen_text())
    results[[name]] <<- list(rows = p$query_one('#process-table')$data, text = text)
  }
  snapshot('startup')
  p$advance(1.1); snapshot('refresh')
  for (key in c('c', 'm', 'p')) {p$press(key); p$advance(1.1); snapshot(paste0('sort-', key))}
  p$press('/'); p$type('alpha'); p$advance(1.1); snapshot('filter')
  stopifnot(p$query_one('#process-table')$row_count == 1L)
  p$press('escape'); p$advance(1.1); p$press('down', 'enter'); snapshot('selection')
  p$resize(42L, 18L); snapshot('resize-small')
  p$resize(120L, 36L); snapshot('resize-large')
  p$press('+', '-', 'h'); p$advance(1.1); snapshot('controls')
  p$press('q'); stopifnot(p$exited, !application$running)
  results$shutdown <- list(exited = p$exited, running = application$running)
  target <- Sys.getenv('TERMR_E_ARTIFACTS', file.path(root, 'audit-results/real-world-apps'))
  dir.create(target, recursive = TRUE, showWarnings = FALSE)
  saveRDS(results, file.path(target, paste0('rtop-', library_kind, '.rds')))
  jsonlite::write_json(list(library = library_kind, version = version, scenarios = names(results), status = 'PASS'),
    file.path(target, paste0('rtop-', library_kind, '.json')), auto_unbox = TRUE, pretty = TRUE)
  cat('RTOP', library_kind, 'PASS', length(results), 'scenarios\n')
}
# The wrapper instruments only the exported run() boundary; terminal mode still
# uses its real POSIX driver. No rtop source or termr internals are patched.
testthat::with_mocked_bindings(env$start_rtop(), run = runner, .package = 'termr')
