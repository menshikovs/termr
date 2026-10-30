suppressMessages(pkgload::load_all(".", quiet = TRUE))
a <- app(vertical(button("a", id = "a"), button("b", id = "b"), id = "root"))
p <- test_app(a, 40, 8); set.seed(2); keys <- c("tab", "shift+tab", "down", "up", "enter", "left", "right")
go <- function(n) { for (i in seq_len(n)) { p$driver$feed(KeyEvent$new(sample(keys, 1))); if (i %% 10 == 0) p$step() }; p$step() }
pr <- a$.__enclos_env__$private
sz <- function(x) as.numeric(lobstr::obj_size(x))
probe <- function() c(queue_items = length(pr$.queue$.__enclos_env__$private$items), n_handlers = length(pr$.handlers), n_bindings = length(pr$.bindings),
  n_actions = length(pr$.actions), later = length(pr$.later), workers = length(pr$.workers), toasts_kids = length(pr$.toasts$children),
  driver_queue = length(p$driver$.__enclos_env__$private$queue), term_osc = length(p$driver$terminal$osc),
  renderer = sz(pr$.renderer), frame = sz(pr$.frame), snapshot = sz(pr$.snapshot), timers = sz(pr$.timers), dirty = length(pr$.dirty),
  screen_children = length(a$screen$children), stack = sz(pr$.screens))
go(500); x0 <- probe(); go(10000); x1 <- probe(); print(rbind(x0, x1, delta = x1 - x0))
cat("environments reachable from the app: "); cat("(skipped)\n")
# is it the byte-code / srcref of closures created per event? count live envs via gc ncells in isolation
e0 <- sum(gc()[1, 2]); go(5000); invisible(gc()); cat("done\n")
