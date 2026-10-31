# Rscript entrypoint: resolve files independently of the process working directory.
phase_e_main <- function() {
entry <- grep('^--file=', commandArgs(FALSE), value = TRUE)
root <- Sys.getenv('TERMR_PROJECT_ROOT', '')
if (!nzchar(root)) {
  if (!length(entry)) stop('Set TERMR_PROJECT_ROOT when sourcing this entrypoint in an R session.')
  root <- dirname(dirname(normalizePath(sub('^--file=', '', entry[[1L]]), winslash = '/', mustWork = TRUE)))
}
root <- normalizePath(root, winslash = '/', mustWork = TRUE)
old_wd <- setwd(root)
on.exit(setwd(old_wd), add = TRUE)
Sys.setenv(TERMR_PROJECT_ROOT = root)
source(file.path(root, 'integration-apps/bootstrap.R'), local = .GlobalEnv)
args <- commandArgs(TRUE)
option <- function(name, default) {
  value <- grep(paste0('^--', name, '='), args, value = TRUE)
  if (length(value)) sub(paste0('^--', name, '='), '', value[[1L]]) else default
}
selected <- match.arg(option('app', 'showcase'), c('showcase', 'analytics', 'monitor'))
mode <- match.arg(option('mode', 'terminal'), c('terminal', 'headless', 'web'))
file <- switch(selected, showcase = '01-termr-showcase', analytics = '02-shiny-visual-analytics', monitor = '03-mirai-nanonext-monitor')
source(file.path('integration-apps', file, 'app.R'), local = .GlobalEnv, encoding = 'UTF-8')
if (mode == 'web') {
  if (selected != 'analytics') stop('Only analytics has a web view.')
  demo <- analytics_dashboard()
  port <- as.integer(option('port', as.character(httpuv::randomPort())))
  ready <- Sys.getenv('TERMR_E_SERVER_READY', '')
  if (nzchar(ready)) jsonlite::write_json(list(port = port), ready, auto_unbox = TRUE)
  stop_path <- Sys.getenv('TERMR_E_STOP', '')
  stopper <- if (nzchar(stop_path)) shiny::observe({
    shiny::invalidateLater(100)
    if (file.exists(stop_path)) shiny::stopApp()
  }, domain = NULL) else NULL
  tryCatch(shiny::runApp(demo$app, host = '127.0.0.1', port = port, launch.browser = FALSE), finally = {
    if (!is.null(stopper)) stopper$destroy()
    demo$close()
    phase_e_mark('web-stopped', demo$diagnostics())
  })
} else {
  demo <- switch(selected, showcase = workbench_app(), analytics = analytics_terminal(), monitor = distributed_monitor())
  if (identical(option('scenario', 'normal'), 'crash')) demo$app$bind('ctrl+e', function(app) stop('Controlled handler failure'))
  if (mode == 'terminal') {
    phase_e_run(demo)
  } else {
    pilot <- NULL
    tryCatch({
      pilot <- termr::test_app(demo$app, width = 100L, height = 30L)
      steps <- as.integer(option('steps', '1'))
      if (steps > 0L) {
        if (selected == 'showcase') pilot$press('f2', 'alt+s', 'alt+s', 'f4', 'f7', 'f10')
        if (selected == 'analytics') pilot$press('f2', 'alt+s', 'f4', 'f4', 'f5')
        if (selected == 'monitor') {
          pilot$press('n')
          deadline <- unname(proc.time()[['elapsed']]) + 15
          repeat {
            pilot$advance(.05)
            if (any(demo$model$rows()$status == 'completed')) break
            if (unname(proc.time()[['elapsed']]) > deadline) stop('Task completion timeout')
            Sys.sleep(.005)
          }
        }
      }
      cat('READY', selected, '\n')
      cat(paste(pilot$screen_text(), collapse = '\n'), '\n')
    }, finally = {
      if (!is.null(pilot)) pilot$stop()
      demo$close()
    })
    cat(jsonlite::toJSON(demo$summary(), auto_unbox = TRUE), '\n')
  }
}
}
phase_e_main()
