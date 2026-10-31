library(ps)
records <- jsonlite::fromJSON(commandArgs(TRUE)[[1L]], simplifyVector = FALSE)
deadline <- proc.time()[['elapsed']] + 5
alive <- function(record) {
  tryCatch(ps::ps_is_running(ps::ps_handle(record$pid, time = record$created)),
    error = function(e) FALSE)
}
repeat {
  running <- vapply(records, alive, TRUE)
  if (!any(running)) break
  if (proc.time()[['elapsed']] > deadline) stop('Owned processes remain: ',
    paste(vapply(records[running],function(x)x$pid,0L),collapse=', '))
  Sys.sleep(.05)
}
cat('OWNED PROCESSES CLOSED:', length(records), '\n')
