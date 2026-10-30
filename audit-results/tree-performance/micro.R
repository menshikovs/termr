suppressMessages(pkgload::load_all(Sys.getenv("PKG", "."), quiet = TRUE))
b <- bench::mark(
  parse_size_fr = parse_size("1fr"), parse_size_auto = parse_size("auto"), parse_size_num = parse_size(3),
  style_default = style(width = "auto", height = "auto", min_width = 10, border = "round", padding = c(0, 1), align = "center"),
  label_new = label("x"), input_new = input("v"), button_new = button("b"), horizontal_new = horizontal(),
  r6_empty = Widget$new(), check = FALSE, min_iterations = 300)
print(b[, c("expression", "median", "mem_alloc", "n_itr")])
lw <- label("x"); bench::mark(default_style_call = lw$default_style(), computed_style = {lw$.__enclos_env__$private$.cache <- NULL; 1}, check = FALSE, min_iterations = 300) -> b2
print(b2[, c("expression", "median", "mem_alloc")])
