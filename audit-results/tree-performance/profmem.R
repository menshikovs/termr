suppressMessages(pkgload::load_all(".", quiet = TRUE))
for (i in 1:20) input("v")
f <- "audit-results/tree-performance/logs/input.profmem"
Rprofmem(f, threshold = 4096); for (i in 1:20) input("v"); Rprofmem(NULL)
l <- readLines(f); cat("allocations >= 4 KB:", length(l), "for 20 inputs\n")
bytes <- as.numeric(sub(" .*", "", l)); cat("total KB per input:", sum(bytes) / 20 / 1024, "\n")
tops <- sub("^[0-9]+ :", "", l); tops <- vapply(strsplit(tops, '" "'), function(p) paste(tail(p, 3), collapse = " > "), "")
print(head(sort(table(tops), decreasing = TRUE), 8))
