suppressMessages(pkgload::load_all(".", quiet = TRUE))
imax <- .Machine$integer.max
try_ <- function(label, expr) { cat(sprintf("%-52s ", label)); flush.console(); r <- withCallingHandlers(tryCatch({ setTimeLimit(elapsed = 8, transient = TRUE); force(expr); "ok" }, error = function(e) paste("ERROR:", substr(conditionMessage(e), 1, 90))), warning = function(w) { invokeRestart("muffleWarning") }); setTimeLimit(); cat(r, "
") }
vals <- list(NA, NA_integer_, NA_real_, NaN, Inf, -Inf, -1, 0, 1.5, imax, imax - 1L, 2^31, 1e10, "NA", "Infpx", "1fr", "-1fr", "0fr", "1e9fr", "150%", "-5%", "NaN%")
for (v in vals) {
  try_(paste("style(width =", deparse(v), ")+render"), { a <- app(vertical(label("hello", style = style(width = v)), label("x"))); p <- test_app(a, 20, 4); p$stop() })
}
for (v in list(NA, Inf, imax, 1e10, -1, 1.5)) {
  try_(paste("style(height =", deparse(v), ")+render"), { a <- app(vertical(label("hello", style = style(height = v)), label("x"))); p <- test_app(a, 20, 4); p$stop() })
}
for (nm in c("padding", "margin", "gap", "min_width", "max_width", "min_height", "max_height")) for (v in list(NA, Inf, imax, -1, 1e10))
  try_(paste0("style(", nm, " = ", deparse(v), ")"), { a <- app(vertical(label("hello", style = do.call(style, setNames(list(v), nm))), label("x"))); p <- test_app(a, 20, 4); p$stop() })
for (v in list(NA, Inf, imax, 0, 1.5)) {
  try_(paste("grid columns =", deparse(v)), { a <- app(grid_layout(label("a"), label("b"), columns = v)); p <- test_app(a, 20, 4); p$stop() })
}
try_("fixed width imax at 10 cols: no overflow", { a <- app(horizontal(label("a", style = style(width = imax)), label("b", style = style(width = imax)))); p <- test_app(a, 10, 2); p$stop() })
try_("deep nest 300 levels", { w <- label("x"); for (i in 1:300) w <- vertical(w); a <- app(w); p <- test_app(a, 20, 4); p$stop() })
try_("wide char label width 1 box", { a <- app(label("你好", style = style(width = 1))); p <- test_app(a, 5, 2); p$stop() })
for (sz in list(c(0, 5), c(5, 0), c(NA, 5), c(-1, 3), c(imax, 2))) try_(paste("test_app size", deparse(sz)), { a <- app(label("x")); p <- test_app(a, sz[1], sz[2]); p$stop() })
