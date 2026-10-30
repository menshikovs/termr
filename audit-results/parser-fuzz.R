suppressMessages(pkgload::load_all(".", quiet = TRUE))
set.seed(7); errs <- 0L; pend <- 0L
frag <- list("\033[", "\033]", "\033O", "\033[<", "\033[200~", "\033[201~", ";", "M", "m", "~", "\xff", "\xc3", "\xe4\xbd", "\xf0\x9f", "\r", "\n", "\t", "\177", "\003", "\004", "1", "99999999999999999999", "\033\033", "\x1b[1;2;3;4;5;6A", "\033[<0;1;1M", "\033[<64;999999;999999M", "paste")
for (i in 1:4000) {
  n <- sample(1:12, 1)
  bytes <- unlist(lapply(seq_len(n), function(j) if (runif(1) < .7) charToRaw(frag[[sample(length(frag), 1)]]) else as.raw(sample(0:255, sample(1:4, 1), TRUE))))
  chunks <- split(bytes, cumsum(runif(length(bytes)) < .3))
  p <- KeyParser$new()
  r <- tryCatch({ ev <- list(); for (ch in chunks) ev <- c(ev, p$feed(ch)); ev <- c(ev, p$flush()); if (p$has_pending()) pend <- pend + 1L; NULL },
                error = function(e) conditionMessage(e), warning = function(w) paste("W:", conditionMessage(w)))
  if (!is.null(r)) { errs <- errs + 1L; if (errs <= 8) cat("input", paste(bytes, collapse = " "), "->", r, "\n") }
}
cat("parser fuzz: 4000 cases, problems", errs, " pending-after-flush", pend, "\n")
# unbounded growth: endless CSI / paste start without end
p <- KeyParser$new(); p$feed(charToRaw("\033[200~")); for (i in 1:200) p$feed(as.raw(rep(65L, 10000)))
cat("2MB inside unterminated paste: pending =", p$has_pending(), "\n")
p <- KeyParser$new(); for (i in 1:100) p$feed(as.raw(c(27L, rep(48L, 5000)))); cat("garbage after ESC done\n")
