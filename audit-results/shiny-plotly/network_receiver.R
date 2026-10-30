source("audit-results/shiny-plotly/environment.R")
library(termr)
endpoint <- Sys.getenv("TERMR_AUDIT_ENDPOINT", "tcp://127.0.0.1:5571")
rpc <- Sys.getenv("TERMR_AUDIT_RPC", "tcp://127.0.0.1:5572")
remote <- termr_nano_connect(endpoint, "system.metrics", rpc, request_timeout = 300)
receiver <- termr_shiny_receiver(remote, max_points = 20L, close_source = TRUE)
shiny::testServer(function(input, output, session) {
  value <- termr_shiny_reactive(receiver, session)
  output$seq <- shiny::renderText(if (is.null(value())) "empty" else value()$sequence)
}, {
  start <- proc.time()[["elapsed"]]
  while ((is.null(receiver$latest()) || receiver$diagnostics()$processed < 2L) && proc.time()[["elapsed"]] - start < 10) {
    receiver$poll(); session$flushReact(); Sys.sleep(.05)
  }
  jsonlite::write_json(list(reactive_sequence = output$seq,
    status = receiver$status(), source_status = remote$status(), diagnostics = receiver$diagnostics()),
    file.path("audit-results/shiny-plotly", paste0("network-receiver-", host, ".json")),
    auto_unbox = TRUE, null = "null", pretty = TRUE)
})
receiver$close()
stopifnot(remote$status()$pending == 0L)
