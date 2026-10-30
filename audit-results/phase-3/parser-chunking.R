suppressMessages(pkgload::load_all(".", quiet = TRUE))
args <- commandArgs(TRUE); n <- as.integer(args[1] %||% 3000)
frags <- c("a", "Z", " ", "\r", "\t", "\177", "\003", "é", "Ж", "你", "😀", "é", "\033[A", "\033[B", "\033[C", "\033[D", "\033[H", "\033[F", "\033[3~", "\033[5~", "\033[Z",
           "\033[1;5C", "\033[1;2A", "\033OP", "\033OQ", "\033[15~", "\033[<0;5;3M", "\033[<0;5;3m", "\033[<64;10;2M", "\033[<35;7;7M", "\033[200~pasted\ntext\033[201~", "\033[200~你好\033[201~",
           "\033a", "\033\033[A", "\033[I", "\033[O", "\033[999z", "\033[", "\033]0;t\007")
sig <- function(e) paste(class(e)[1], e$type %||% "", e$key %||% "", e$text %||% "", e$screen_x %||% "", e$screen_y %||% "", e$action %||% "", e$button %||% "", e$direction %||% "")
run <- function(chunks) { p <- KeyParser$new(); ev <- list(); for (ch in chunks) ev <- c(ev, p$feed(ch)); ev <- c(ev, p$flush()); vapply(ev, sig, "") }
set.seed(11); bad <- 0L
for (i in seq_len(n)) {
  s <- paste(sample(frags, sample(1:8, 1), TRUE), collapse = "")
  bytes <- charToRaw(enc2utf8(s))
  ref <- run(list(bytes))
  cuts <- sort(unique(sample.int(length(bytes), min(length(bytes), sample(1:6, 1)), FALSE)))
  idx <- split(seq_along(bytes), findInterval(seq_along(bytes), cuts, left.open = TRUE))
  alt <- run(lapply(idx, function(j) bytes[j]))
  per_byte <- run(lapply(bytes, function(b) b))
  for (cand in list(alt, per_byte)) if (!identical(cand, ref)) { bad <- bad + 1L; if (bad <= 6) cat("MISMATCH input", deparse(s), "\n  one-shot:", paste(ref, collapse = " | "), "\n  chunked :", paste(cand, collapse = " | "), "\n"); break }
}
cat("chunking differential: cases", n, " mismatches", bad, "\n")
# post-close / flush behaviours
p <- KeyParser$new(); p$feed(charToRaw("\033")); cat("lone ESC pending:", p$has_pending(), " flush ->", paste(vapply(p$flush(), sig, ""), collapse = ","), "\n")
cat("feed after flush ok:", length(p$feed(charToRaw("a"))), "event\n")
