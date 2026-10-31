# Safe, bounded R expression generation for DataTable selections and views.
# The generated expression is always built from language objects. `parse()` is
# used only on scalar literals emitted by `dput()`; user-provided text is never
# parsed or evaluated.

termr_repro_limits <- list(rows = 1000L, cells = 10000L, bytes = 1000000L,
                           edits = 1000L, depth = 40L)

termr_r_call <- function(head, args = list(), names = NULL) {
  if (is.null(names)) names <- rep("", length(args))
  call <- c(list(head), args)
  names(call) <- c("", names)
  as.call(call)
}

termr_r_ns <- function(package, name) {
  as.call(list(as.name("::"), as.name(package), as.name(name)))
}

termr_r_special <- function(text) {
  # The tokens are fixed internal R constants, never user input.
  parse(text = text, keep.source = FALSE)[[1L]]
}

termr_r_string <- function(x) {
  parsed <- parse(text = paste(utils::capture.output(dput(enc2utf8(x))), collapse = "\n"),
                  keep.source = FALSE)
  parsed[[1L]]
}

termr_r_block <- function(expressions) {
  if (length(expressions) == 1L) return(expressions[[1L]])
  as.call(c(list(as.name("{")), expressions))
}

termr_r_qualify_new <- function(x) {
  if (is.call(x)) {
    if (identical(x[[1L]], as.name("new"))) x[[1L]] <- termr_r_ns("methods", "new")
    for (i in seq_along(x)[-1L]) x[[i]] <- termr_r_qualify_new(x[[i]])
  }
  x
}

termr_r_class_support <- function(x) {
  if (!is.object(x)) return(list(ok = TRUE, packages = character()))
  classes <- class(x)
  packages <- character()
  allowed <- list(
    c("factor"), c("ordered", "factor"), c("Date"), c("POSIXct", "POSIXt"),
    c("difftime"), c("hms", "difftime"), c("units"),
    c("haven_labelled", "vctrs_vctr", "double"),
    c("haven_labelled", "vctrs_vctr", "integer"),
    c("haven_labelled", "vctrs_vctr", "character"),
    c("haven_labelled_spss", "haven_labelled", "vctrs_vctr", "double"),
    c("haven_labelled_spss", "haven_labelled", "vctrs_vctr", "integer"),
    c("haven_labelled_spss", "haven_labelled", "vctrs_vctr", "character"),
    c("integer64"), c("Period"), c("Duration"), c("Interval"),
    c("blob", "vctrs_list_of", "vctrs_vctr", "list"),
    c("tbl_df", "tbl", "data.frame"), c("data.frame"), c("sf", "data.frame"),
    c("symbolic_units"), c("bbox"), c("crs")
  )
  if (any(vapply(allowed, identical, logical(1), classes))) {
    if ("hms" %in% classes) packages <- c(packages, "hms")
    if ("units" %in% classes) packages <- c(packages, "units")
    if (any(grepl("^haven_labelled", classes))) packages <- c(packages, "haven")
    if ("integer64" %in% classes) packages <- c(packages, "bit64")
    if (any(classes %in% c("Period", "Duration", "Interval"))) packages <- c(packages, "lubridate")
    if ("blob" %in% classes) packages <- c(packages, "blob")
    if ("tbl_df" %in% classes) packages <- c(packages, "tibble")
    if ("sf" %in% classes) packages <- c(packages, "sf")
    if ("symbolic_units" %in% classes) packages <- c(packages, "units")
    return(list(ok = TRUE, packages = unique(packages)))
  }
  # sf geometry vectors have a controlled class family, while arbitrary
  # extension classes remain unsupported.
  if ("sfc" %in% classes && all(grepl("^sfc(_[[:alnum:]_]+)?$", classes))) {
    return(list(ok = TRUE, packages = "sf"))
  }
  geometry_types <- c("POINT", "LINESTRING", "POLYGON", "MULTIPOINT", "MULTILINESTRING",
                      "MULTIPOLYGON", "GEOMETRY", "CIRCULARSTRING", "COMPOUNDCURVE",
                      "CURVEPOLYGON", "MULTICURVE", "MULTISURFACE", "POLYHEDRALSURFACE",
                      "TIN", "TRIANGLE")
  if ("sfg" %in% classes && all(classes %in% c("sfg", "XY", "XYZ", "XYM", "XYZM", geometry_types))) {
    return(list(ok = TRUE, packages = "sf"))
  }
  list(ok = FALSE, packages = character(), reason = paste0(
    "Class is not in the reproducible-code whitelist: ", paste(classes, collapse = "/"), "."))
}

termr_r_value_support <- function(x, depth = 0L) {
  fail <- function(reason) list(ok = FALSE, packages = character(), reason = reason)
  if (depth > termr_repro_limits$depth) return(fail("Nested value exceeds the supported depth."))
  if (is.environment(x) || is.function(x) || typeof(x) %in% c("externalptr", "weakref", "language", "symbol", "expression", "pairlist")) {
    return(fail("Value contains executable or process-local R state."))
  }
  if (isS4(x)) {
    cls <- class(x)[[1L]]
    if (!cls %in% c("Period", "Duration", "Interval")) return(fail("S4 class is not supported for code export."))
    packages <- "lubridate"
    for (slot_name in methods::slotNames(x)) {
      child <- termr_r_value_support(methods::slot(x, slot_name), depth + 1L)
      if (!child$ok) return(child)
      packages <- c(packages, child$packages)
    }
    return(list(ok = TRUE, packages = unique(packages)))
  }
  cls <- termr_r_class_support(x)
  if (!cls$ok) return(cls)
  if (is.character(x) && any(Encoding(x) == "bytes")) return(fail("Byte-encoded strings cannot be represented safely as source text."))
  packages <- cls$packages
  if (is.list(x)) {
    for (i in seq_along(x)) {
      child <- termr_r_value_support(x[[i]], depth + 1L)
      if (!child$ok) return(child)
      packages <- c(packages, child$packages)
    }
  }
  attrs <- attributes(x)
  if (length(attrs)) {
    for (name in setdiff(names(attrs), "class")) {
      child <- termr_r_value_support(attrs[[name]], depth + 1L)
      if (!child$ok) return(child)
      packages <- c(packages, child$packages)
    }
  }
  list(ok = TRUE, packages = unique(packages))
}

termr_r_parse_literal <- function(x) {
  old <- options(digits = 17)
  on.exit(options(old), add = TRUE)
  text <- paste(utils::capture.output(dput(x, control = c("keepNA", "keepInteger"))), collapse = "\n")
  parsed <- parse(text = text, keep.source = FALSE)
  if (length(parsed) != 1L) stop("Could not produce one R literal.", call. = FALSE)
  parsed[[1L]]
}

termr_r_atomic_ast <- function(x) {
  # haven stores tagged missing values in special double payloads. `dput()`
  # writes those as ordinary NA, so preserve tags explicitly in the vector AST.
  tagged <- rep(FALSE, length(x))
  tags <- rep(NA_character_, length(x))
  if (typeof(x) == "double" && requireNamespace("haven", quietly = TRUE)) {
    tagged <- tryCatch(haven::is_tagged_na(x), error = function(e) tagged)
    if (any(tagged)) tags <- haven::na_tag(x)
  }
  if (any(tagged)) {
    values <- lapply(seq_along(x), function(i) {
      if (tagged[[i]]) {
        return(termr_r_call(termr_r_ns("haven", "tagged_na"), list(termr_r_string(tags[[i]]))))
      }
      termr_r_scalar_ast(x[[i]])
    })
    return(termr_r_call(as.name("c"), values))
  }
  if (!length(x)) {
    constructor <- switch(typeof(x), logical = "logical", integer = "integer", double = "double",
                          character = "character", raw = "raw", NULL)
    if (is.null(constructor)) stop("Unsupported atomic storage type.", call. = FALSE)
    return(termr_r_call(as.name(constructor)))
  }
  if (typeof(x) %in% c("logical", "integer", "double", "character")) {
    values <- lapply(seq_along(x), function(i) termr_r_scalar_ast(x[[i]]))
    if (length(values) == 1L) return(values[[1L]])
    return(termr_r_call(as.name("c"), values))
  }
  # `dput()` on a bare vector is a literal only; attributes are reattached
  # separately below, so an input class cannot emit an arbitrary constructor.
  value <- x
  attributes(value) <- NULL
  termr_r_parse_literal(value)
}

termr_r_scalar_ast <- function(x) {
  if (is.logical(x)) {
    if (is.na(x)) return(termr_r_special("NA"))
    return(termr_r_parse_literal(x))
  }
  if (is.integer(x)) {
    if (is.na(x)) return(termr_r_call(as.name("as.integer"), list(termr_r_special("NA"))))
    return(termr_r_parse_literal(x))
  }
  if (is.double(x)) {
    if (is.nan(x)) return(termr_r_call(as.name("as.numeric"), list(termr_r_string("NaN"))))
    if (is.na(x)) return(termr_r_call(as.name("as.numeric"), list(termr_r_special("NA"))))
    if (is.infinite(x)) {
      return(termr_r_call(as.name("as.numeric"), list(termr_r_string(if (x > 0) "Inf" else "-Inf"))))
    }
    # R's deparser rounds numeric literals for display even with digits=17.
    # Parsing a quoted 17-digit decimal reproduces the original IEEE double.
    return(termr_r_call(as.name("as.numeric"),
                        list(termr_r_string(sprintf("%.17g", x)))))
  }
  if (is.character(x)) {
    if (is.na(x)) return(termr_r_call(as.name("as.character"), list(termr_r_special("NA"))))
    return(termr_r_string(x))
  }
  termr_r_parse_literal(x)
}

termr_r_attr_args <- function(attrs) {
  if (!length(attrs)) return(list())
  lapply(attrs, termr_r_value_ast)
}

termr_r_structure_ast <- function(base, attrs) {
  if (!length(attrs)) return(base)
  values <- c(list(base), termr_r_attr_args(attrs))
  termr_r_call(as.name("structure"), values, names = c("", names(attrs)))
}

termr_r_value_ast <- function(x) {
  if (is.null(x)) return(termr_r_call(as.name("attributes"),
                                      list(termr_r_call(as.name("list")))))
  if (isS4(x)) {
    slot_names <- methods::slotNames(x)
    args <- lapply(slot_names, function(name) termr_r_value_ast(methods::slot(x, name)))
    return(termr_r_call(termr_r_ns("methods", "new"),
                         c(list(termr_r_string(class(x)[[1L]])), args),
                         names = c("", slot_names)))
  }
  attrs <- attributes(x)
  if (inherits(x, "integer64")) {
    text <- as.character(x)
    text[is.na(x)] <- NA_character_
    arg <- if (length(text)) termr_r_call(as.name("c"), lapply(text, termr_r_string)) else
      termr_r_call(as.name("character"))
    base <- termr_r_call(termr_r_ns("bit64", "as.integer64"), list(arg))
  } else if (is.list(x)) {
    base <- termr_r_call(as.name("list"), lapply(x, termr_r_value_ast))
  } else if (is.atomic(x)) {
    base <- termr_r_atomic_ast(x)
  } else {
    stop("Value has no safe R source representation.", call. = FALSE)
  }
  termr_r_structure_ast(base, attrs)
}

termr_r_code <- function(expression, packages = character()) {
  guards <- lapply(packages, function(package) {
    require <- termr_r_call(as.name("requireNamespace"),
                            list(termr_r_string(package), TRUE), c("", "quietly"))
    condition <- termr_r_call(as.name("!"), list(require))
    message <- paste0("Generated R code requires the optional package '", package, "'.")
    stop_call <- termr_r_call(as.name("stop"), list(termr_r_string(message), FALSE), c("", "call."))
    termr_r_call(as.name("if"), list(condition, stop_call))
  })
  ast <- termr_r_block(c(guards, list(expression)))
  ast <- termr_r_qualify_new(ast)
  old <- options(digits = 17)
  on.exit(options(old), add = TRUE)
  paste(deparse(ast, width.cutoff = 80L, control = "keepInteger"), collapse = "\n")
}

termr_r_result <- function(code = NULL, status, reason = NULL, packages = character(),
                           requires_source_binding = FALSE, model = list()) {
  structure(list(code = code, status = status, reason = reason,
                 packages = unique(packages), requires_source_binding = requires_source_binding,
                 model = model), class = "termr_reproducible_code")
}

termr_r_filter_summary <- function(filters) {
  if (!length(filters)) return(list())
  lapply(names(filters), function(name) {
    filter <- filters[[name]]
    list(column = name,
         type = if (inherits(filter, "termr_table_filter")) filter$type else "function",
         reproducible = inherits(filter, "termr_table_filter"))
  }) |>
    stats::setNames(names(filters))
}

termr_r_filter_supported <- function(filter, x) {
  if (!inherits(filter, "termr_table_filter")) return("Function filters have no safe portable representation.")
  if (is.list(x) || isS4(x) || is.object(x) && !inherits(x, c("factor", "ordered", "Date", "POSIXct", "difftime"))) {
    return("This filter column has class-specific comparison semantics.")
  }
  if (filter$type %in% c("contains", "regex") && !(is.character(x) || is.factor(x))) {
    return("Text filters can only be reproduced for character and factor columns.")
  }
  if (filter$type == "range" && !(is.integer(x) || is.double(x) || inherits(x, c("Date", "POSIXct", "difftime", "ordered")))) {
    return("Range filters are not portable for this column type.")
  }
  NULL
}

termr_r_data_col <- function(name, rows = NULL) {
  expr <- termr_r_call(as.name("[["), list(as.name(".termr_data"), termr_r_string(name)))
  if (!is.null(rows)) expr <- termr_r_call(as.name("["), list(expr, rows))
  expr
}

termr_r_filter_expr <- function(name, filter) {
  column <- termr_r_data_col(name, as.name(".termr_rows"))
  missing <- termr_r_call(as.name("is.na"), list(column))
  if (filter$type == "missing") return(missing)
  if (filter$type == "equals") {
    missing_value <- length(filter$value) == 1L && is.atomic(filter$value) &&
      tryCatch(isTRUE(is.na(filter$value)), error = function(e) FALSE)
    if (missing_value) return(missing)
    compare <- termr_r_call(as.name("=="), list(column, termr_r_value_ast(filter$value)))
    not_missing <- termr_r_call(as.name("!"), list(missing))
    return(termr_r_call(as.name("&"), list(not_missing, compare)))
  }
  if (filter$type %in% c("contains", "regex")) {
    text <- termr_r_call(as.name("as.character"), list(column))
    pattern <- termr_r_string(filter$value)
    if (filter$type == "contains" && !filter$case_sensitive) {
      text <- termr_r_call(as.name("tolower"), list(text))
      pattern <- termr_r_call(as.name("tolower"), list(pattern))
    }
    call <- if (filter$type == "contains") {
      termr_r_call(as.name("grepl"), list(pattern, text, TRUE), c("", "", "fixed"))
    } else {
      termr_r_call(as.name("grepl"), list(pattern, text, TRUE, !filter$case_sensitive),
                   c("", "", "perl", "ignore.case"))
    }
    return(termr_r_call(as.name("&"),
      list(termr_r_call(as.name("!"), list(missing)), call)))
  }
  lower_op <- if (filter$inclusive) ">=" else ">"
  upper_op <- if (filter$inclusive) "<=" else "<"
  lower <- termr_r_call(as.name(lower_op), list(column, termr_r_value_ast(filter$min)))
  upper <- termr_r_call(as.name(upper_op), list(column, termr_r_value_ast(filter$max)))
  termr_r_call(as.name("&"), list(termr_r_call(as.name("&"),
    list(termr_r_call(as.name("!"), list(missing)), lower)), upper))
}

termr_r_pipeline_ast <- function(model) {
  expressions <- list(as.call(list(as.name("<-"), as.name(".termr_data"), as.name("data"))))
  rows <- if (is.null(model$base_rows)) {
    termr_r_call(as.name("seq_len"), list(termr_r_call(as.name("nrow"), list(as.name(".termr_data")))))
  } else termr_r_value_ast(model$base_rows)
  expressions[[length(expressions) + 1L]] <- as.call(list(as.name("<-"), as.name(".termr_rows"), rows))
  for (filter_name in names(model$filters)) {
    filter <- model$filters[[filter_name]]
    condition <- termr_r_filter_expr(filter_name, filter)
    subset <- termr_r_call(as.name("["), list(as.name(".termr_rows"), condition))
    expressions[[length(expressions) + 1L]] <- as.call(list(as.name("<-"), as.name(".termr_rows"), subset))
  }
  if (!is.null(model$sort)) {
    # Applying stable radix sorts from the last key to the first reproduces
    # DataTable's multi-key order while keeping NA values last.
    for (k in rev(seq_along(model$sort$columns))) {
      name <- model$sort$columns[[k]]
      key <- termr_r_data_col(name, as.name(".termr_rows"))
      order_call <- termr_r_call(as.name("order"),
        list(key, model$sort$decreasing[[k]], TRUE, "radix"),
        c("", "decreasing", "na.last", "method"))
      subset <- termr_r_call(as.name("["), list(as.name(".termr_rows"), order_call))
      expressions[[length(expressions) + 1L]] <- as.call(list(as.name("<-"), as.name(".termr_rows"), subset))
    }
  }
  if (!is.null(model$selection)) {
    subset <- termr_r_call(as.name("["), list(as.name(".termr_rows"), termr_r_value_ast(model$selection)))
    expressions[[length(expressions) + 1L]] <- as.call(list(as.name("<-"), as.name(".termr_rows"), subset))
  }
  columns <- termr_r_call(as.name("c"), lapply(model$columns, termr_r_string))
  result <- termr_r_call(as.name("["), list(as.name(".termr_data"), as.name(".termr_rows"), columns, FALSE),
                         c("", "", "", "drop"))
  expressions[[length(expressions) + 1L]] <- result
  termr_r_call(as.name("local"), list(termr_r_block(expressions)))
}

termr_r_edit_ast <- function(edits) {
  expressions <- list(as.call(list(as.name("<-"), as.name(".termr_data"), as.name("data"))))
  for (edit in edits) {
    lhs <- termr_r_call(as.name("[["), list(as.name(".termr_data"), termr_r_string(edit$column)))
    lhs <- termr_r_call(as.name("[["), list(lhs, as.integer(edit$row)))
    expressions[[length(expressions) + 1L]] <- as.call(list(as.name("<-"), lhs, termr_r_value_ast(edit$value)))
  }
  expressions[[length(expressions) + 1L]] <- as.name(".termr_data")
  termr_r_call(as.name("local"), list(termr_r_block(expressions)))
}

