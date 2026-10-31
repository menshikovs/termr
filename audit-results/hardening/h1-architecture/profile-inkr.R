pkgload::load_all(".", quiet = TRUE)
stopifnot(requireNamespace("inkr", quietly = TRUE))
out <- "audit-results/hardening/h1-architecture"
ns <- asNamespace("termr")
bridge <- get("inkr_style_for_widget", ns)
element_for <- get("inkr_element_for_widget", ns)
sheet <- inkr::ink_compile(inkr::ink_parse(".root { color: cyan; } .root .item { padding: 0; }"))
make_app <- function(n, unique_ids = FALSE, enabled = TRUE) {
  children <- lapply(seq_len(n), function(i) label(as.character(i),
    id = if (unique_ids) paste0("item_", i) else NULL, classes = "item"))
  root <- do.call(vertical, c(children, list(classes = "root")))
  app(root, inkr_stylesheet = if (enabled) sheet else NULL)
}
rows <- list()
for (scenario in c("no_inkr", "repeated_paths", "unique_paths")) {
  a <- make_app(2000L, scenario == "unique_paths", scenario != "no_inkr")
  path <- file.path(out, paste0("profile-", scenario, ".out"))
  Rprof(path, interval = .002, line.profiling = TRUE)
  elapsed <- unname(system.time(render_widget(a, 80L, 24L))["elapsed"])
  Rprof(NULL)
  summary <- summaryRprof(path, lines = "both")
  write.csv(summary$by.total, file.path(out, paste0("profile-", scenario, "-total.csv")))
  write.csv(summary$by.self, file.path(out, paste0("profile-", scenario, "-self.csv")))
  cache <- as.list(a$.__enclos_env__$private$.inkr_cache, all.names = TRUE)
  rows[[scenario]] <- data.frame(scenario = scenario, widgets = 2000L, elapsed_s = elapsed,
    cache_entries = length(cache), cache_payload_bytes = as.numeric(object.size(cache)))
}
results <- do.call(rbind, rows)
write.csv(results, file.path(out, "inkr-profile-summary.csv"), row.names = FALSE)
print(results, row.names = FALSE)

a <- make_app(100L)
w <- a$screen$children[[1L]]$children[[1L]]
element <- element_for(w)
bridge(a, w)
times <- c(
  element_path_1000 = unname(system.time(for (i in seq_len(1000L)) element_for(w))["elapsed"]),
  public_compute_1000 = unname(system.time(for (i in seq_len(1000L)) inkr::ink_compute(sheet, element))["elapsed"]),
  bridge_cache_hit_1000 = unname(system.time(for (i in seq_len(1000L)) bridge(a, w))["elapsed"]),
  tree_walk_100 = unname(system.time(for (i in seq_len(100L)) a$screen$walk())["elapsed"])
)
write.csv(data.frame(operation = names(times), elapsed_s = unname(times)), file.path(out, "inkr-micro-profile.csv"), row.names = FALSE)
print(times)
session_rows <- lapply(c(100L, 1000L, 2000L), function(n) {
  s <- inkr::ink_session(sheet)
  inkr::ink_session_set(s, "root", type = "Vertical", classes = "root")
  path <- tempfile()
  Rprofmem(path)
  time <- unname(system.time(for (i in seq_len(n)) inkr::ink_session_set(s, paste0("child", i),
    type = "Label", classes = "item", parent_key = "root"))["elapsed"])
  Rprofmem(NULL)
  bytes <- suppressWarnings(as.numeric(sub(":.*$", "", readLines(path, warn = FALSE))))
  unlink(path)
  data.frame(siblings = n, elapsed_s = time, gross_alloc_bytes = sum(bytes, na.rm = TRUE))
})
session_rows <- do.call(rbind, session_rows)
write.csv(session_rows, file.path(out, "inkr-session-insertion.csv"), row.names = FALSE)
print(session_rows, row.names = FALSE)
