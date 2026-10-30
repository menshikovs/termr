suppressMessages(pkgload::load_all(".", quiet = TRUE))
args <- commandArgs(TRUE); nseeds <- as.integer(args[1] %||% 400)
rs <- function(r) sample(r, 1)
rand_dim <- function() switch(rs(1:6), "auto", "auto", rs(0:12), "1fr", paste0(rs(1:3), "fr"), paste0(rs(c(0, 10, 50, 100)), "%"))
texts <- c("", "x", "hello world", "你好世界", "😀😀", "éé", "a\nb\nc", strrep("long ", 12))
rand_style <- function() {
  args <- list(width = rand_dim(), height = rand_dim())
  if (runif(1) < .3) args$padding <- rs(0:2)
  if (runif(1) < .2) args$margin <- rs(0:2)
  if (runif(1) < .25) args$border <- sample(c("round", "single", "none"), 1)
  if (runif(1) < .15) args$min_width <- rs(0:6)
  if (runif(1) < .15) args$max_width <- rs(0:15)
  if (runif(1) < .15) args$max_height <- rs(0:6)
  do.call(style, args)
}
gen <- function(depth) {
  k <- if (depth >= 3) 1 else rs(1:5)
  if (k <= 2) return(switch(rs(1:4), label(sample(texts, 1), style = rand_style(), wrap = sample(c("none", "word", "char"), 1)),
                            button(sample(texts, 1), style = rand_style()), input(sample(texts, 1), style = rand_style()), label(sample(texts, 1), style = rand_style(), visible = runif(1) < .7)))
  kids <- replicate(rs(0:4), gen(depth + 1), simplify = FALSE)
  switch(rs(1:4), do.call(vertical, c(kids, list(style = rand_style(), visible = runif(1) < .85))),
         do.call(horizontal, c(kids, list(style = rand_style(), visible = runif(1) < .85))),
         do.call(grid_layout, c(kids, list(columns = rs(1:3), gap = rs(0:1), style = rand_style()))),
         do.call(scroll_view, c(kids, list(style = rand_style()))))
}
walk <- function(w, f) { f(w); for (k in w$children) walk(k, f) }
snapshot <- function(root) { out <- character(); walk(root, function(w) { r <- w$region; out[length(out) + 1L] <<- if (is.null(r)) "NULL" else paste(r$x, r$y, r$width, r$height) }); out }
viol <- list(); rec <- function(seed, kind, msg) viol[[length(viol) + 1L]] <<- data.frame(seed = seed, kind = kind, msg = substr(msg, 1, 120))
sizes <- list(c(1, 1), c(2, 1), c(3, 3), c(10, 4), c(20, 8), c(40, 12), c(80, 24))
for (seed in seq_len(nseeds)) {
  set.seed(seed)
  root_widget <- gen(0); sz <- sizes[[rs(seq_along(sizes))]]
  a <- app(root_widget)
  res <- tryCatch({
    scr <- a$screen; bounds <- rect(1L, 1L, sz[1], sz[2])
    layout_tree(scr, bounds); s1 <- snapshot(scr)
    layout_tree(scr, bounds); s2 <- snapshot(scr)
    if (!identical(s1, s2)) rec(seed, "idempotence", "second layout differs")
    # inner checks
    walk(scr, function(w) {
      r <- w$region
      if (is.null(r)) { if (isTRUE(w$visible) && !is.null(w$parent) && isTRUE(w$parent$visible)) NULL; return() }
      vals <- c(r$x, r$y, r$width, r$height)
      if (anyNA(vals) || any(!is.finite(vals))) rec(seed, "non-finite", paste(class(w)[1], paste(vals, collapse = ",")))
      else if (r$width < 0 || r$height < 0) rec(seed, "negative size", paste(class(w)[1], paste(vals, collapse = ",")))
      else if (!is.integer(r$x) || !is.integer(r$width)) rec(seed, "non-integer", class(w)[1])
      if (!w$visible && !is.null(r) && (r$width > 0 && r$height > 0)) rec(seed, "hidden has area", class(w)[1])
    })
    # determinism: same tree rebuilt from same seed
    set.seed(seed); rw2 <- gen(0); a2 <- app(rw2); layout_tree(a2$screen, bounds)
    if (!identical(snapshot(a2$screen), s1)) rec(seed, "determinism", "rebuilt tree differs")
    # shrink: must not error; then re-grow equals original
    layout_tree(scr, rect(1L, 1L, 1L, 1L)); layout_tree(scr, bounds)
    if (!identical(snapshot(scr), s1)) rec(seed, "shrink-regrow", "layout after 1x1 round trip differs")
    # full pipeline render
    p <- test_app(a, sz[1], sz[2]); inc <- p$screen_text(); fr <- compose_frame(a$screen, sz[1], sz[2])$to_text()
    if (!identical(inc, fr)) rec(seed, "render mismatch", "initial render != compose")
    p$resize(max(1, sz[1] %/% 2), max(1, sz[2] %/% 2)); p$resize(sz[1], sz[2])
    if (!identical(p$screen_text(), compose_frame(a$screen, sz[1], sz[2])$to_text())) rec(seed, "resize mismatch", "after resize round trip")
    if (any(vapply(p$screen_text(), str_width, 0L) > sz[1])) rec(seed, "overflow", "line wider than terminal")
    p$stop(); NULL
  }, error = function(e) conditionMessage(e))
  if (!is.null(res)) rec(seed, "error", res)
}
df <- if (length(viol)) do.call(rbind, viol) else data.frame()
cat("layout property run: seeds", nseeds, " violations", nrow(df), "\n")
if (nrow(df)) { print(table(df$kind)); print(head(df, 12), row.names = FALSE) }
