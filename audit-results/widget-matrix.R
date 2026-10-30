suppressMessages(pkgload::load_all(".", quiet = TRUE))
W <- "你好\U0001F600"; C <- "é‍"; txts <- c("", "x", W, "ab你cd", C, "\x1b[31mred", "line1\nline2\ttab", strrep("w", 60))
mk <- list(
  input = function(t) input(t), password = function(t) input(t, password = TRUE),
  text_area = function(t) text_area(t), label = function(t) label(t), label_w = function(t) label(t, wrap = "word"),
  label_c = function(t) label(t, wrap = "char"), button = function(t) button(t), checkbox = function(t) checkbox(t),
  option_list = function(t) option_list(c(t, "b", W)), radio = function(t) radio_set(radio_button(t), radio_button(W)),
  select = function(t) dropdown(c(t, "b", W)), tabs = function(t) tabs(tab(t, label("c")), tab(W, label("d"))),
  tree = function(t) tree_view(tree_node(t, children = list(tree_node(W)))),
  table = function(t) data_table(data.frame(a = c(t, W), b = 1:2, stringsAsFactors = FALSE)),
  log = function(t) { l <- log_view(); l$write(t); l }, progress = function(t) progress_bar(0.5),
  panel = function(t) panel(label(t), title = t), status = function(t) status_bar(t), markdown = function(t) markdown_view(t),
  scroll = function(t) scroll_view(label(t)), kv = function(t) key_value(t, W), metric = function(t) metric(t, W),
  sparkline = function(t) sparkline(c(1, 3, 2)), spinner = function(t) spinner(t)
)
keys <- c("tab", "enter", "down", "up", "left", "right", "end", "home", "backspace", "delete", "pagedown", "escape", "a", "你", "shift+tab", "space")
sizes <- list(c(1,1), c(2,1), c(1,3), c(3,2), c(5,3), c(8,2), c(12,4), c(30,5))
bad <- 0L; log <- list()
for (nm in names(mk)) for (ti in seq_along(txts)) {
  set.seed(ti)
  for (sz in sizes) {
    r <- tryCatch({
      a <- app(vertical(mk[[nm]](txts[[ti]]), input("你好", id = "z")))
      p <- test_app(a, sz[1], sz[2])
      for (k in sample(keys, 8, TRUE)) p$press(k)
      p$resize(sz[2] + 1L, sz[1] + 1L); p$resize(sz[1], sz[2])
      inc <- p$screen_text(); full <- compose_frame(a$screen, sz[1], sz[2])$to_text()
      p$stop()
      if (!identical(inc, full)) "MISMATCH incremental vs full" else if (any(vapply(inc, str_width, 0L) > sz[1])) "OVERFLOW" else NULL
    }, error = function(e) paste("ERROR:", conditionMessage(e)))
    if (!is.null(r)) { bad <- bad + 1L; if (bad <= 40) cat(sprintf("%-10s text#%d %dx%d: %s\n", nm, ti, sz[1], sz[2], r)) }
  }
}
cat("combinations with problems:", bad, "of", length(mk) * length(txts) * length(sizes), "\n")
df <- do.call(rbind, log); df$kind <- sub(":.*", "", ifelse(grepl("^ERROR", df$r), df$r, df$r))
print(table(df$w, substr(df$r, 1, 12)))
print(head(df[grepl("^ERROR", df$r), ], 20))
print(head(df[df$w != "select" & grepl("MISMATCH|OVERFLOW", df$r), ], 30))
