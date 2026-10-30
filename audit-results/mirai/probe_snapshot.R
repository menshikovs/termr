source("audit-results/mirai/environment.R")
source("inst/examples/mirai-tasks/producer.R")
args <- commandArgs(trailingOnly = TRUE)
before <- length(args) && args[[1L]] == "before"
if (before) {
  # Minimal pre-fix return-before-finally logic, isolated from networking.
  old_producer <- function() {
    model <- task_demo_model(2L)
    on.exit(model$close(), add = TRUE)
    for (i in 1:4) model$submit(chunks = 160L)
    model$snapshot()
  }
  final <- old_producer()
} else final <- task_producer(.1, "tcp://127.0.0.1:0", "tcp://127.0.0.1:0")
jsonlite::write_json(final, file.path("audit-results/mirai", paste0("snapshot-", if (before) "before" else "after", ".json")),
  auto_unbox = TRUE, na = "null", null = "null", pretty = TRUE)
stopifnot(all(vapply(final$tasks, function(task) task$status == "cancelled", logical(1))), final$counts$cancelled == 4)
