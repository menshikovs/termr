phase_e_test_root <- Sys.getenv('TERMR_PROJECT_ROOT', normalizePath('../..', winslash = '/'))
Sys.setenv(TERMR_PROJECT_ROOT = phase_e_test_root)
source(file.path(phase_e_test_root, 'integration-apps/bootstrap.R'), local = .GlobalEnv)
for (path in c('01-termr-showcase', '02-shiny-visual-analytics', '03-mirai-nanonext-monitor')) {
  source(file.path(phase_e_root, 'integration-apps', path, 'app.R'), local = .GlobalEnv, encoding = 'UTF-8')
}
press_button <- function(pilot, id) {pilot$focus(paste0('#', id)); pilot$press('enter')}
enter_text <- function(pilot, id, value) {
  pilot$focus(paste0('#', id)); pilot$press('end', 'ctrl+u'); pilot$type(value)
}
wait_real <- function(predicate, timeout = 15, step = function() NULL) {
  deadline <- unname(proc.time()[['elapsed']]) + timeout
  repeat {
    step()
    if (isTRUE(predicate())) return(invisible(TRUE))
    if (unname(proc.time()[['elapsed']]) > deadline) stop('Condition timed out', call. = FALSE)
    Sys.sleep(.005)
  }
}
