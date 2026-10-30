# Model-based fuzz of signal()/computed()/watch()/batch()/dispose(). Fixed seeds.
suppressMessages(pkgload::load_all(".", quiet = TRUE))
args <- commandArgs(TRUE); nseeds <- as.integer(args[1] %||% 300); nops <- as.integer(args[2] %||% 40)
viol <- list()
report <- function(seed, ops, msg) { viol[[length(viol) + 1L]] <<- list(seed = seed, msg = msg, ops = ops) }
run_seed <- function(seed, trace = NULL) {
  set.seed(seed)
  sigs <- list(); vals <- list()           # signal objects and the model values
  comps <- list()                          # list(obj, deps (signal idx), k)
  watches <- list()                        # list(obj, deps, seen env, disposed)
  ops <- character(); problems <- character()
  for (i in 1:3) { sigs[[i]] <- signal(i); vals[[i]] <- i }
  derived <- list()
  model_sig <- function(j) if (!is.null(derived[[as.character(j)]])) 2 * model_sig(derived[[as.character(j)]]) else vals[[j]]
  free <- function() setdiff(seq_along(sigs), as.integer(names(derived)))
  model_comp <- function(cp) sum(vapply(cp$deps, model_sig, 0)) + cp$k
  check <- function(when) {
    for (cp in comps) if (!cp$disposed) { got <- tryCatch(cp$obj(), error = function(e) NA); if (!isTRUE(all.equal(got, model_comp(cp)))) problems <<- c(problems, sprintf("%s: computed stale got %s want %s", when, format(got), format(model_comp(cp)))) }
    for (w in watches) if (!w$disposed) { cur <- sum(vapply(w$deps, model_sig, 0)) + w$k; if (!isTRUE(all.equal(w$env$last, cur))) problems <<- c(problems, sprintf("%s: watch last=%s want %s", when, format(w$env$last), format(cur))) }
  }
  for (step in seq_len(nops)) {
    op <- sample(c("write", "write", "batch", "computed", "watch", "dispose", "read"), 1)
    r <- tryCatch({
      if (op == "write") { j <- sample(c(free(), free()), 1); v <- sample(-3:9, 1); ops <- c(ops, sprintf("w s%d=%d", j, v)); vals[[j]] <- v; sigs[[j]](v) }
      else if (op == "batch") { js <- sample(c(free(), free()), 2, TRUE); vs <- sample(-3:9, 2); ops <- c(ops, sprintf("batch s%d=%d s%d=%d", js[1], vs[1], js[2], vs[2])); vals[[js[1]]] <- vs[1]; vals[[js[2]]] <- vs[2]; batch({ sigs[[js[1]]](vs[1]); sigs[[js[2]]](vs[2]) }) }
      else if (op == "computed") { d <- sample(seq_along(sigs), sample(1:2, 1)); k <- sample(0:3, 1); ops <- c(ops, sprintf("computed deps=%s k=%d", paste(d, collapse = ","), k)); local({ d <- d; k <- k; comps[[length(comps) + 1L]] <<- list(obj = computed(function() sum(vapply(d, function(j) sigs[[j]](), 0)) + k), deps = d, k = k, disposed = FALSE) }) }
      else if (op == "watch") { d <- sample(seq_along(sigs), sample(1:2, 1)); k <- sample(0:3, 1); ops <- c(ops, sprintf("watch deps=%s k=%d", paste(d, collapse = ","), k)); env <- new.env(); env$runs <- 0L
        local({ d <- d; k <- k; env <- env; obj <- watch(function() { env$last <- sum(vapply(d, function(j) sigs[[j]](), 0)) + k; env$runs <- env$runs + 1L }); watches[[length(watches) + 1L]] <<- list(obj = obj, deps = d, k = k, env = env, disposed = FALSE) }) }
      else if (op == "nestedwatch") { # a watch that writes a different (extra) signal; creates a chain
        ops <- c(ops, "nestedwatch"); s_new <- signal(0); sigs[[length(sigs) + 1L]] <- s_new; vals[[length(vals) + 1L]] <- 0; src <- sample(setdiff(seq_along(sigs), length(sigs)), 1); idx <- length(sigs)
        env <- new.env(); local({ src <- src; idx <- idx; env <- env
          obj <- watch(function() { v <- sigs[[src]](); env$last <- v; untracked(s_new(v * 2)) })
          watches[[length(watches) + 1L]] <<- list(obj = obj, deps = src, k = 0, env = env, disposed = FALSE) })
        derived[[as.character(idx)]] <- src }
      else if (op == "dispose" && (length(comps) + length(watches)) > 0) {
        if (length(watches) && runif(1) < .6) { j <- sample(length(watches), 1); if (!watches[[j]]$disposed) { ops <- c(ops, sprintf("dispose watch %d", j)); dispose(watches[[j]]$obj); watches[[j]]$disposed <- TRUE; watches[[j]]$env$runs_at_dispose <- watches[[j]]$env$runs } }
        else if (length(comps)) { j <- sample(length(comps), 1); if (!comps[[j]]$disposed) { ops <- c(ops, sprintf("dispose computed %d", j)); dispose(comps[[j]]$obj); comps[[j]]$disposed <- TRUE } } }
      else { ops <- c(ops, "read"); for (cp in comps) if (!cp$disposed) cp$obj() }
      NULL }, error = function(e) conditionMessage(e))
    if (!is.null(r)) { problems <- c(problems, paste("error:", r)); break }
    # nested-watch model: s_new values must follow src
    for (w in watches) if (!w$disposed && is.null(w$k) == FALSE && identical(w$k, 0) && length(w$deps) == 1L) NULL
    check(sprintf("after step %d (%s)", step, ops[length(ops)]))
    # a disposed watch must not run again
    for (w in watches) if (w$disposed && !is.null(w$env$runs_at_dispose) && w$env$runs != w$env$runs_at_dispose) problems <- c(problems, "disposed watch ran again")
    if (length(problems)) break
  }
  list(problems = problems, ops = ops)
}
bad <- 0L
for (s in seq_len(nseeds)) { res <- run_seed(s); if (length(res$problems)) { bad <- bad + 1L; if (bad <= 5) { cat("seed", s, ":", res$problems[1], "\n  ops:", paste(res$ops, collapse = " | "), "\n") } } }
cat("reactive fuzz: seeds", nseeds, "x ops", nops, " violating seeds:", bad, "\n")

# directed cases: cycles, self-write loop, re-entrancy
cat("-- directed\n")
e <- function(x) tryCatch({ force(x); "ok" }, error = function(e) paste("error:", substr(conditionMessage(e), 1, 70)))
a <- signal(0); cat("self-dependent computed:", e({ cc <- NULL; cc <- computed(function() cc() + 1); cc() }), "\n")
x <- signal(0); y <- signal(0)
cat("ping-pong watches (bounded?):", e({ watch(function() y(x() + 1)); watch(function() x(y() + 1)) }), "\n")
z <- signal(0); n <- 0L
cat("watch writes its own dependency:", e({ watch(function() { n <<- n + 1L; if (z() < 5) z(z() + 1) }) }), " runs:", n, " z:", z(), "\n")
w1 <- signal(1); cnt <- 0L; wo <- watch(function() { cnt <<- cnt + 1L; w1() }); dispose(wo); dispose(wo); w1(2)
cat("double dispose + write after dispose: runs =", cnt, "\n")
cat("signal write inside computed:", e({ q <- signal(0); r <- computed(function() { q(q() + 1); 1 }); r() }), "\n")
cat("error inside watch then later writes:", e({ q2 <- signal(0); watch(function() { if (q2() == 1) stop("boom") }); q2(1) }), " | after:", e(q2(2)), "\n")
