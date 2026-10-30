suppressMessages(pkgload::load_all(".", quiet = TRUE))
tryit <- function(label, expr) {
  r <- tryCatch({ force(expr); "ok" }, error = function(e) paste("ERROR:", conditionMessage(e)),
                warning = function(w) paste("WARN:", conditionMessage(w)))
  cat(sprintf("%-55s %s\n", label, r))
}
mk <- function() app(vertical(label("hello world", id = "l"), input(id = "i"), button("B", id = "b"), id = "root"))

a <- mk()
for (v in list(NA, NA_integer_, Inf, -1, 0, 1.5, "a", c(1, 2), TRUE, NULL, 1e9, 1e5))
  tryit(paste("layout_diagnostics width =", deparse(v)[1]), a$layout_diagnostics(width = v, height = 3))
for (v in list(NA, Inf, 0, -2, "x", 1e9))
  tryit(paste("layout_diagnostics height =", deparse(v)[1]), a$layout_diagnostics(width = 10, height = v))
tryit("1x1", print(nrow(a$layout_diagnostics(1, 1))))

# unstarted app: does it leave state changed?
a2 <- mk()
tryit("diag on unstarted app", a2$layout_diagnostics(5, 2))
# repeated: regions stable?
p <- test_app(mk(), 30, 6);

r0 <- p$app$query_one("#l")$region
for (i in 1:5) p$app$layout_diagnostics(7, 2)
stopifnot(identical(p$app$query_one("#l")$region, r0))
cat("region stable: TRUE\n")
fr <- p$screen_text(); p$app$layout_diagnostics(3, 3); p$step(); fr2 <- p$screen_text()
cat("screen unchanged after diag+step:", identical(fr, fr2), "\n")
p$stop()

# error in layout restore: a widget whose content_width errors
bad <- widget("bad", render = function(self, ...) stop("boom"))
tryit("diag with widget render error", { b <- app(bad()); b$layout_diagnostics(10, 3) })

# custom layout w/o proper measure
tryit("register custom layout", {
  register_layout("custom_probe", function(children, inner, parent_style) lapply(children, function(c) inner),
                  function(children, parent_style) list(width = function() 3L, height = function(w) 2L), replace = TRUE)
  b <- app(vertical(label("a"), label("b"), style = style(layout = "custom_probe")))
  print(b$layout_diagnostics(1, 1))
})

# hidden container & hidden child
tryit("hidden subtree", { b <- app(vertical(label("a long label text", visible = FALSE), vertical(label("zzzzzzzzzzzzz"), visible = FALSE))); print(nrow(b$layout_diagnostics(3, 1))) })
# visible arg validation
for (v in list(NA, NULL, "yes", c(TRUE, FALSE), 1))
  tryit(paste("label(visible =", deparse(v)[1], ")"), label("x", visible = v))
for (v in list(NA, NULL, 0))
  tryit(paste("grid_layout(visible =", deparse(v)[1], ")"), grid_layout(label("x"), visible = v))
W <- widget("w2", state = list(n = 0))
tryit("custom widget visible=FALSE", stopifnot(!W(visible = FALSE)$visible))
tryit("custom widget visible=NA", W(visible = NA))

# wait_until_exit
tryit("wait_until_exit timeout=0 not exited", { p <- test_app(mk()); on.exit(p$stop()); p$wait_until_exit(0) })
tryit("wait_until_exit timeout=NA", { p <- test_app(mk()); p$wait_until_exit(NA) })
tryit("wait_until_exit interval huge", { p <- test_app(mk()); p$wait_until_exit(1, 1e6) })
tryit("wait_until_exit interval tiny", { p <- test_app(mk()); p$wait_until_exit(0.01, 1e-12) })
tryit("wait_until_exit with exit(NULL)", { a3 <- mk(); a3$set_timeout(0.1, function(app) app$exit()); p <- test_app(a3); print(p$wait_until_exit(1)) })
tryit("wait_until_exit error in callback", { a3 <- mk(); a3$set_timeout(0.1, function(app) stop("cb")); p <- test_app(a3); p$wait_until_exit(1) })
tryit("wait_until_exit with worker", {
  a3 <- mk(); p <- test_app(a3)
  a3$run_worker(function() { Sys.sleep(0.3); 1 })
  a3$set_timeout(0.05, function(app) app$exit("w"))
  print(p$wait_until_exit(3))
})
cat("done\n")
