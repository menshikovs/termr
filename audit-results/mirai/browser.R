source("audit-results/mirai/environment.R")
source("inst/examples/mirai-tasks/shiny.R")
args <- commandArgs(trailingOnly = TRUE)
mode <- if (length(args)) args[[1L]] else "direct"
base <- file.path(root, "audit-results/mirai")
stop_file <- file.path(base, "STOP_BROWSER")
unlink(stop_file)
demo <- task_shiny(mode)
diagnostic <- function() list(mode = mode, receiver = demo$receiver$diagnostics(),
  pool = if (is.null(demo$pool)) NULL else demo$pool$diagnostics())
write_diag <- function() {
  if (demo$receiver$is_closed()) return(invisible(NULL))
  if (file.exists(stop_file)) {shiny::stopApp(); return(invisible(NULL))}
  jsonlite::write_json(diagnostic(), file.path(base, "browser-diagnostic.json"), auto_unbox = TRUE, null = "null")
  later::later(write_diag, .5)
}
write_diag()
tryCatch(shiny::runApp(demo$app, host = "127.0.0.1", port = 3840L, launch.browser = FALSE), finally = {
  demo$close()
  jsonlite::write_json(diagnostic(), file.path(base, paste0("browser-shutdown-", mode, ".json")), auto_unbox = TRUE, null = "null")
})
