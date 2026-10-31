args <- commandArgs(TRUE)
phase <- args[[1L]]
out <- "audit-results/hardening/h3-performance"
pkgload::load_all(".", quiet = TRUE)
ns <- asNamespace("termr")
set.seed(20261031)
events <- list()
for (n in c(1L, 100L, 10000L)) for (rep in 0:3) {
  q <- get("EventQueue", ns)$new()
  messages <- lapply(seq_len(n), function(i) Event$new("h3.benchmark", data = list(index = i)))
  push <- system.time(for (e in messages) q$push(e))[["elapsed"]]
  pop <- system.time(while (!q$is_empty()) q$pop())[["elapsed"]]
  if (rep) events[[length(events) + 1L]] <- data.frame(n, rep, enqueue_s = push, dequeue_s = pop)
}
write.csv(do.call(rbind, events), file.path(out, paste0(phase, "-lifecycle-event-times.csv")), row.names = FALSE)
live <- list()
for (i in 1:1000) {
  s <- termr_stream(history = 0L)
  c <- line_chart(numeric(), numeric(), interactive = FALSE)
  a <- app(vertical(c, button("one"), button("two")))
  p <- test_app(a, width = 30, height = 8)
  c$bind_stream(s, function(v) v$x, function(v) v$y, max_points = 20L)
  s$emit(list(x = i, y = i)); p$step()
  c$unbind_stream()
  stopifnot(s$subscriber_count() == 0L)
  p$stop(); s$close()
  stopifnot(!a$running)
  rm(p, a, c, s)
  if (i %% 100 == 0) {
    g <- gc()
    live[[length(live) + 1L]] <- data.frame(cycles = i, ncells = g[1, "used"], vcells = g[2, "used"],
      connections = nrow(showConnections(all = TRUE)))
    write.csv(do.call(rbind, live), file.path(out, paste0(phase, "-memory.csv")), row.names = FALSE)
    cat("cycles", i, "\n"); flush.console()
  }
}
