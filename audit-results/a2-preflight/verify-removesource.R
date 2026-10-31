stopifnot("removeSource" %in% getNamespaceExports("utils"))
stopifnot(!exists("removeSource", envir = baseenv(), inherits = FALSE))
pkgload::load_all(".", quiet = TRUE)

fn <- eval(parse(text = "function(value) value + 1L", keep.source = TRUE))
stopifnot(!is.null(attr(fn, "srcref")))
wire <- getFromNamespace("mirai_prepare_job", "termr")(
  fn, list(value = 1L), character(), 1024L
)
job <- unserialize(wire)
stopifnot(is.null(attr(job$fn, "srcref")))
stopifnot(is.null(attr(body(job$fn), "srcref")))
stopifnot(identical(job$fn(1L), 2L))
cat("R ", as.character(getRversion()),
    ": utils::removeSource available; base::removeSource absent; prepared job passed.\n",
    sep = "")
