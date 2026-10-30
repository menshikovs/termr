# Differential fuzz: incrementally painted virtual terminal vs. fresh full compose.
suppressMessages(pkgload::load_all(".", quiet = TRUE))
args <- commandArgs(TRUE); seeds <- seq_len(as.integer(args[1] %||% 30)); nsteps <- as.integer(args[2] %||% 60)
texts <- c("hello", "Привет, мир", "你好世界你好世界", "😀😀😀 emoji", "éé combining", "a\tb\tc", "line1\nline2\nline3",
           paste(rep("long word", 20), collapse = " "), "👨‍👩‍👧 zwj", "\x1b[31mred\x1b[0m", "", "x", "漢字かな交じり文")
keys <- c("tab","shift+tab","enter","escape","up","down","left","right","backspace","delete","home","end","a","Ж","你","😀"," ","ctrl+a","ctrl+e","ctrl+k","pageup","pagedown")
sizes <- list(c(1,1), c(3,2), c(10,5), c(20,10), c(40,15), c(80,24), c(25,7))
mk <- function(rnd) {
  txt <- function() sample(texts, 1)
  wrap <- sample(c("none","word","char"), 1)
  app(vertical(
    label(txt(), id = "l1", wrap = wrap),
    horizontal(label(txt(), id = "l2"), button("OK", id = "b1"), input(txt(), id = "i1")),
    grid_layout(label(txt(), wrap = "word"), label(txt()), columns = 2, id = "g"),
    text_area(txt(), id = "ta"),
    scroll_view(label(paste(rep(txt(), 12), collapse = "\n"), id = "sv"), id = "scr"),
    checkbox("chk", id = "c1"), 
    id = "root"))
}
bad <- 0L
for (seed in seeds) {
  set.seed(seed)
  sz <- sizes[[sample(length(sizes), 1)]]
  a <- mk(); p <- test_app(a, sz[1], sz[2])
  for (step in seq_len(nsteps)) {
    op <- sample(c("key","key","resize","text","hide","type","scroll","focus","nest"), 1)
    desc <- op
    r <- tryCatch({
      if (op == "key") { k <- sample(keys, 1); desc <- paste("key", k); p$press(k) }
      else if (op == "resize") { s <- sizes[[sample(length(sizes),1)]]; desc <- paste("resize", s[1], s[2]); p$resize(s[1], s[2]) }
      else if (op == "text") { id <- sample(c("#l1","#l2","#sv"), 1); t <- sample(texts, 1); desc <- paste("text", id, deparse(t)); a$query_one(id)$update(t); p$step() }
      else if (op == "hide") { id <- sample(c("#l1","#b1","#g","#scr","#c1","#i1"), 1); w <- a$query_one(id); desc <- paste("toggle", id); w$visible <- !w$visible; p$step() }
      else if (op == "scroll") { dy <- sample(-4:6, 1); desc <- paste("scroll", dy); a$query_one("#scr")$scroll_by(0L, dy); p$step() }
      else if (op == "focus") { ids <- c("#i1","#b1","#ta","#c1","#scr"); id <- sample(ids, 1); desc <- paste("focus", id); w <- a$query_one(id); if (w$is_displayed()) w$focus(); p$step() }
      else if (op == "nest") { desc <- "nest"; host <- a$query_one("#root"); inner <- scroll_view(label(paste(rep(sample(texts, 1), 8), collapse = "
")), vertical(label(sample(texts, 1)), input(sample(texts, 1))), style = style(height = 4)); host$mount(inner); p$step() }
      else { t <- sample(texts, 1); desc <- paste("type", deparse(t)); p$type(t) }
      NULL }, error = function(e) conditionMessage(e))
    if (!is.null(r)) { cat(sprintf("seed %d step %d [%s] ERROR: %s\n", seed, step, desc, r)); bad <- bad + 1L; break }
    size <- p$driver$size()
    # screen after incremental paint
    inc <- p$screen_text()
    full <- tryCatch(compose_frame(a$screen, size[["width"]], size[["height"]])$to_text(), error = function(e) paste("COMPOSE ERROR", conditionMessage(e)))
    if (!identical(inc, full)) {
      cat(sprintf("seed %d step %d [%s] size %dx%d MISMATCH\n", seed, step, desc, size[["width"]], size[["height"]]))
      d <- which(inc != full)[1]; cat("  inc :", inc[d], "\n  full:", full[d], "\n"); bad <- bad + 1L; break
    }
    # width invariant
    w <- max(0L, vapply(inc, str_width, integer(1)))
    if (w > size[["width"]] || length(inc) > size[["height"]]) { cat(sprintf("seed %d step %d overflow %d\n", seed, step, w)); bad <- bad + 1L; break }
  }
  try(p$stop(), silent = TRUE)
}
cat("seeds", length(seeds), "problems", bad, "\n")
