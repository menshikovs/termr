suppressMessages(pkgload::load_all(".", quiet = TRUE))
# where does the remaining per-widget time go? time R6 instantiation vs. Widget initialize pieces
b <- bench::mark(r6_new_widget = Widget$new(), r6_new_label = Label$new("x"), label_fn = label("x"), merge_default = merge_styles(style(width = "auto"), style(height = 1)),
                 computed_style = { w <- label("x"); 1 }, check = FALSE, min_iterations = 500)
print(b[, c("expression", "median", "mem_alloc")])
env_cost <- bench::mark(new_env_300_fns = { e <- new.env(); for (i in 1:70) assign(paste0("f", i), function() NULL, envir = e); e }, check = FALSE, min_iterations = 500)
print(env_cost[, c("expression", "median")])
cat("methods in Widget public env:", length(Widget$public_methods), " active:", length(Widget$active), " private:", length(Widget$private_methods), "\n")
cat("Label chain:", paste(class(label("x")), collapse = " > "), "\n")
n_methods <- function(g) { n <- 0; while (!is.null(g)) { n <- n + length(g$public_methods) + length(g$private_methods) + length(g$active); g <- g$get_inherit() }; n }
cat("total R6 members instantiated for a Label:", n_methods(Label), " Input:", n_methods(Input), " Button:", n_methods(Button), "\n")
