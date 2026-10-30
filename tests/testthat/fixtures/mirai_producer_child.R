config <- jsonlite::read_json(commandArgs(trailingOnly = TRUE)[[1L]], simplifyVector = TRUE)
.libPaths(config$libraries)
env <- new.env()
source(config$producer, local = env)
env$task_producer(seconds = 20, endpoint = "tcp://127.0.0.1:0", snapshot_endpoint = "tcp://127.0.0.1:0",
  ready_file = config$ready, stop_file = config$stop)
