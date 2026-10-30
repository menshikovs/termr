suppressMessages(pkgload::load_all(".", quiet = TRUE))
t <- function(f, n = 1000) { gc(); round(system.time(for (i in 1:n) f())[["elapsed"]] / n * 1000, 3) }
cat("ms per construction (n=1000):\n")
for (nm in c("label", "input", "button", "checkbox", "horizontal()", "vertical()")) {
  f <- switch(nm, label = function() label("x"), input = function() input("v"), button = function() button("b"), checkbox = function() checkbox("c"), `horizontal()` = function() horizontal(), `vertical()` = function() vertical())
  cat(sprintf("  %-14s %s\n", nm, t(f)))
}
kids <- lapply(1:3, function(i) label("k")); 
cat("horizontal with 3 fresh children:", t(function() horizontal(label("a"), label("b"), label("c"))), "\n")
# growth with number of children in one container (quadratic?)
for (n in c(100, 400, 1600)) cat(sprintf("vertical of %4d labels: construct %.0f ms (of which labels %.0f ms)\n", n,
  system.time({ ls_ <- lapply(1:n, function(i) label("x")); v <- do.call(vertical, ls_) })[["elapsed"]] * 1000, system.time(lapply(1:n, function(i) label("x")))[["elapsed"]] * 1000))
