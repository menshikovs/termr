pkgload::load_all(".", quiet = TRUE)
out <- "audit-results/hardening/h1-architecture"
files <- list.files("R", full.names = TRUE, pattern = "\\.R$")
usage <- do.call(rbind, lapply(files, function(file) {
  lines <- readLines(file, warn = FALSE)
  calls <- regmatches(lines, gregexpr("[A-Za-z][A-Za-z0-9.]*:::{0,1}[A-Za-z_.][A-Za-z0-9_.]*", lines, perl = TRUE))
  hits <- which(lengths(calls) > 0L)
  if (!length(hits)) return(NULL)
  do.call(rbind, lapply(hits, function(i) data.frame(file = file, line = i, call = calls[[i]])))
}))
write.csv(usage, file.path(out, "namespace-usage.csv"), row.names = FALSE)
ns <- asNamespace("termr")
classes <- Filter(function(name) inherits(get(name, ns), "R6ClassGenerator"), ls(ns, all.names = TRUE))
hierarchy <- do.call(rbind, lapply(classes, function(name) {
  gen <- get(name, ns)
  data.frame(name = name, inherits = paste(deparse(gen$inherit), collapse = " "),
    public_fields = paste(names(gen$public_fields), collapse = ", "),
    active_fields = paste(names(gen$active), collapse = ", "),
    methods = paste(names(gen$public_methods), collapse = ", "))
}))
write.csv(hierarchy, file.path(out, "r6-classes.csv"), row.names = FALSE)
exports <- read.csv(file.path(out, "exports.csv"), stringsAsFactors = FALSE)$name
aliases <- unlist(lapply(list.files("man", pattern = "\\.Rd$", full.names = TRUE), function(file) {
  lines <- readLines(file, warn = FALSE)
  sub("^\\\\alias\\{(.*)\\}$", "\\1", grep("^\\\\alias\\{", lines, value = TRUE))
}))
cat("R6 generators:", length(classes), "\n")
cat("Exports without Rd aliases:", paste(setdiff(exports, aliases), collapse = ", "), "\n")
cat("Triple-colon calls in R source:", sum(grepl(":::", usage$call, fixed = TRUE)), "\n")
print(sort(table(sub("::.*", "", usage$call)), decreasing = TRUE))
