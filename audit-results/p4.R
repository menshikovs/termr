suppressMessages(pkgload::load_all(".", quiet = TRUE))
mkapp <- function() app(vertical(label("Привет 你好 😀"), input(id="in"), text_area(id="ta"), button("OK", id="ok"), label("", id="out"), id="root"))
atoms <- list("\t","\033[Z","\r","\033","\033[A","\033[B","\033[C","\033[D","\177","\033[3~","\033[H","\033[F","a","Ж","你","😀"," ","\033[200~paste\033[201~","\033[<0;5;3M","\033[<0;5;3m","\033[1;5C","\033O","\033[","\033[99999999999999999999~")
for (sz in list(c(10,5), c(40,15))) {
 for (a1 in atoms) { for (a2 in atoms) {
  p <- test_app(mkapp(), sz[1], sz[2])
  r <- tryCatch({ ev <- KeyParser$new(); evs <- c(ev$feed(paste0(a1,a2)), ev$flush()); for (e in evs) p$driver$feed(e); p$step(); NULL}, error=function(e) conditionMessage(e))
  if (!is.null(r)) cat(sz, deparse(a1), deparse(a2), "->", r, "\n")
  try(p$stop(), silent=TRUE)
 }}
}
cat("done\n")
