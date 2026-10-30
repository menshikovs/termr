suppressMessages(pkgload::load_all(".", quiet = TRUE))
mkapp <- function() app(vertical(label("Привет 你好 😀"), input(id="in"), text_area(id="ta"), button("OK", id="ok"), label("", id="out"), id="root"))
for (nm in c("full","noinput","noTA","label-only","button-only")) {
 ui <- switch(nm, full=mkapp(), noinput=app(vertical(label("x"), text_area(id="ta"))), noTA=app(vertical(label("x"), input(id="in"))),
   `label-only`=app(label("hi")), `button-only`=app(button("OK")))
 p <- test_app(ui, 30, 10)
 r <- withCallingHandlers(tryCatch({p$driver$feed(ResizeEvent$new(1,1)); p$step(); "ok"}, error=function(e) conditionMessage(e)),
   error=function(e) { cs <- sys.calls(); cat(nm, "CALLS:\n"); for (c in tail(cs, 12)) cat("  ", substr(paste(deparse(c)[1]), 1, 110), "\n") })
 cat(nm, "->", r, "\n")
}
