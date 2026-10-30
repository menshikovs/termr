suppressMessages(pkgload::load_all(".", quiet = TRUE))
mkapp <- function() app(vertical(label("Привет 你好 😀"), input(id="in"), text_area(id="ta"), button("OK", id="ok"), label("", id="out"), id="root"))
args <- commandArgs(TRUE)
j <- jsonlite::fromJSON(args[1], simplifyVector = FALSE)
hex2raw <- function(h) as.raw(strtoi(substring(h, seq(1, nchar(h), 2), seq(2, nchar(h), 2)), 16L))
p <- test_app(mkapp(), j$cols, j$rows)
kp <- KeyParser$new()
n <- 0
show_calls <- function(e) {
  cs <- sys.calls()
  for (cl in tail(cs, 16)) cat("  ", substr(deparse(cl)[1], 1, 130), "\n")
}
for (s in j$steps) {
  n <- n + 1
  if (s[[1]] == "k") evs <- kp$feed(hex2raw(s[[2]])) else evs <- list(ResizeEvent$new(s[[3]], s[[2]]))
  r <- tryCatch(withCallingHandlers({ for (e in evs) p$driver$feed(e); p$step(); NULL }, error = show_calls),
                error = function(e) conditionMessage(e))
  if (!is.null(r)) { cat("ERR at step", n, ":", r, "\n"); str(s); break }
}
cat("end\n")
