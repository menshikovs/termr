pkgload::load_all(".", quiet = TRUE)
lines <- readLines("R/testing.R", warn = FALSE)
first <- grep("^Pilot <- R6::R6Class", lines)[[1L]]
source <- paste(lines[seq.int(first, length(lines))], collapse = "\n")
inspect <- function(text) {
  notes <- character()
  result <- withCallingHandlers(roxygen2::roc_proc_text(roxygen2::rd_roclet(), text),
    warning = function(w) { notes <<- c(notes, conditionMessage(w)); invokeRestart("muffleWarning") },
    message = function(m) { notes <<- c(notes, conditionMessage(m)); invokeRestart("muffleMessage") })
  list(diagnostics = notes, generated_topics = length(result))
}
cat("Internal Pilot without a roxygen block:\n")
dput(inspect(source))
cat("Same source explicitly marked internal/noRd:\n")
dput(inspect(paste("#' Internal headless test driver.\n#' @noRd", source, sep = "\n")))
