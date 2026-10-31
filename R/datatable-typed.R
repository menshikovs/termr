# Sample list-column edges when inferring whether a list contains raw values;
# never scan a large list solely to choose its display type.
table_list_contains_raw_sample <- function(x) {
  if (!is.list(x) || is.data.frame(x) || !length(x)) return(FALSE)
  n <- length(x)
  rows <- if (n <= 1000L) seq_len(n) else c(seq_len(500L), seq.int(n - 499L, n))
  any(vapply(x[rows], is.raw, logical(1), USE.NAMES = FALSE))
}

table_list_contains_sfg_sample <- function(x) {
  if (!is.list(x) || is.data.frame(x) || !length(x)) return(FALSE)
  n <- length(x)
  rows <- if (n <= 1000L) seq_len(n) else c(seq_len(500L), seq.int(n - 499L, n))
  sample <- x[rows]
  has_geometry <- any(vapply(sample, inherits, logical(1), "sfg", USE.NAMES = FALSE))
  has_geometry && all(vapply(sample, function(value) is.null(value) || inherits(value, "sfg"),
                             logical(1), USE.NAMES = FALSE))
}

# Internal type adapters for the in-memory DataTable. Specialized handlers are
# ordered before the generic S3/vctrs compatibility adapter and bare fallback.
# The list is deliberately private: package methods, pillar, and vctrs provide
# the extension points without a process-global mutable registry.
table_type_handlers <- local({
  list(
    blob = list(
      id = "blob", type = "blob",
      matches = function(x) inherits(x, "blob"),
      editable = function(x) FALSE
    ),
    sfc = list(
      id = "sfc", type = "sfc",
      matches = function(x) inherits(x, "sfc"),
      editable = function(x) FALSE
    ),
    sfg = list(
      id = "sfg", type = "sfg",
      matches = function(x) inherits(x, "sfg"),
      editable = function(x) FALSE
    ),
    sfg_list = list(
      id = "sfg_list", type = "list<sfg>",
      matches = table_list_contains_sfg_sample,
      editable = function(x) FALSE
    ),
    raw = list(
      id = "raw", type = "raw",
      matches = is.raw,
      editable = function(x) FALSE
    ),
    raw_list = list(
      id = "raw_list", type = "list<raw>",
      matches = table_list_contains_raw_sample,
      editable = function(x) FALSE
    ),
    integer64 = list(
      id = "integer64", type = "int64",
      matches = function(x) inherits(x, "integer64"),
      editable = function(x) requireNamespace("bit64", quietly = TRUE)
    ),
    units = list(
      id = "units", type = "unit",
      matches = function(x) inherits(x, "units"),
      editable = function(x) requireNamespace("units", quietly = TRUE)
    ),
    labelled_spss = list(
      id = "labelled_spss", type = "lbl+spss",
      matches = function(x) inherits(x, "haven_labelled_spss"),
      editable = function(x) table_labelled_editable(x)
    ),
    labelled = list(
      id = "labelled", type = "lbl",
      matches = function(x) inherits(x, "haven_labelled"),
      editable = function(x) table_labelled_editable(x)
    ),
    hms = list(
      id = "hms", type = "time",
      matches = function(x) identical(class(x), c("hms", "difftime")),
      editable = function(x) TRUE
    ),
    ordered = list(
      id = "ordered", type = "ord",
      matches = function(x) is.ordered(x) && identical(class(x), c("ordered", "factor")),
      editable = function(x) TRUE
    ),
    factor = list(
      id = "factor", type = "fct",
      matches = function(x) is.factor(x) && identical(class(x), "factor"),
      editable = function(x) TRUE
    ),
    posixct = list(
      id = "posixct", type = "dttm",
      matches = function(x) inherits(x, "POSIXct") && identical(class(x), c("POSIXct", "POSIXt")),
      editable = function(x) TRUE
    ),
    date = list(
      id = "date", type = "date",
      matches = function(x) inherits(x, "Date") && identical(class(x), "Date"),
      editable = function(x) TRUE
    ),
    difftime = list(
      id = "difftime", type = "drtn",
      matches = function(x) inherits(x, "difftime") && identical(class(x), "difftime"),
      editable = function(x) TRUE
    ),
    logical = list(
      id = "logical", type = "lgl",
      matches = function(x) is.logical(x) && !is.object(x),
      editable = function(x) TRUE
    ),
    integer = list(
      id = "integer", type = "int",
      matches = function(x) is.integer(x) && !is.object(x),
      editable = function(x) TRUE
    ),
    double = list(
      id = "double", type = "dbl",
      matches = function(x) is.double(x) && !is.object(x),
      editable = function(x) TRUE
    ),
    character = list(
      id = "character", type = "chr",
      matches = function(x) is.character(x) && !is.object(x),
      editable = function(x) TRUE
    ),
    list = list(
      id = "list", type = "list",
      matches = function(x) is.list(x) &&
        (!is.object(x) || identical(class(x), "AsIs")),
      editable = function(x) FALSE
    ),
    extension = list(
      id = "extension", type = "obj",
      matches = is.object,
      editable = function(x, prototype = NULL) table_vctrs_text_cast_capable(x, prototype)
    ),
    unsupported = list(
      id = "unsupported", type = "obj",
      matches = function(x) TRUE,
      editable = function(x) FALSE
    )
  )
})

table_type_handler <- function(x) {
  for (handler in table_type_handlers) {
    matched <- tryCatch(isTRUE(handler$matches(x)), error = function(e) FALSE)
    if (matched) return(handler)
  }
  table_type_handlers$unsupported
}

table_column_prototype <- function(x) {
  if (requireNamespace("vctrs", quietly = TRUE)) {
    ptype <- tryCatch(vctrs::vec_ptype(x), error = function(e) NULL)
    if (!is.null(ptype)) return(ptype)
  }
  tryCatch(x[FALSE], error = function(e) structure(vector(typeof(x), 0L), class = class(x)))
}

table_type_summary <- function(x, handler = table_type_handler(x)) {
  if (handler$id %in% c("blob", "raw")) return(handler$type)
  if (handler$id == "raw_list") return(handler$type)
  if (handler$id %in% c("sfc", "sfg", "sfg_list")) return(handler$type)
  if (handler$id %in% c("labelled", "labelled_spss")) {
    base <- table_labelled_type_code(x)
    suffix <- if (handler$id == "labelled_spss") "+spss" else ""
    return(paste0(base, "+lbl", suffix))
  }
  if (handler$id == "extension") return(table_extension_type_summary(x))
  value <- NULL
  if (requireNamespace("pillar", quietly = TRUE)) {
    value <- tryCatch(as.character(pillar::type_sum(x)), error = function(e) NULL)
  }
  if (length(value) != 1L || is.na(value) || !nzchar(value)) value <- handler$type
  if (handler$id == "units") {
    unit <- table_units_label(x)
    if (nzchar(unit)) value <- paste0(value, " [", unit, "]")
  }
  value
}

table_extension_class_label <- function(x) {
  classes <- tryCatch(class(x), error = function(e) character())
  classes <- sanitize_text(classes)
  classes <- classes[!is.na(classes) & nzchar(classes)]
  if (!length(classes)) return("object")
  str_truncate(classes[[1L]], 24L)
}

table_extension_type_summary <- function(x) {
  value <- NULL
  if (requireNamespace("pillar", quietly = TRUE)) {
    value <- tryCatch(pillar::type_sum(x), error = function(e) NULL)
  } else if (requireNamespace("vctrs", quietly = TRUE)) {
    prototype <- table_column_prototype(x)
    value <- tryCatch(vctrs::vec_ptype_abbr(prototype), error = function(e) NULL)
  }
  if (!is.character(value) || length(value) != 1L || is.na(value)) {
    value <- table_extension_class_label(x)
  }
  value <- tryCatch(trimws(sanitize_text(unclass(value))), error = function(e) "")
  if (!nzchar(value)) value <- table_extension_class_label(x)
  str_truncate(value, 24L)
}

table_has_s3_method <- function(generic, x, package) {
  if (!requireNamespace(package, quietly = TRUE)) return(FALSE)
  classes <- tryCatch(class(x), error = function(e) character())
  if (!length(classes)) return(FALSE)
  any(vapply(classes, function(class_name) {
    !is.null(tryCatch(
      utils::getS3method(generic, class_name, optional = TRUE,
                         envir = asNamespace(package)),
      error = function(e) NULL
    ))
  }, logical(1), USE.NAMES = FALSE))
}

# Text becomes a custom vctrs vector only through its directed cast method.
# An empty cast is used once during column inspection to check that the class
# opts into this exact source/target direction and restores its prototype.
table_vctrs_text_cast <- function(text, prototype) {
  fail <- function(message) list(value = NULL, error = message)
  if (!requireNamespace("vctrs", quietly = TRUE)) {
    return(fail("Editing this custom class requires the optional vctrs package."))
  }
  if (!is.character(text) || is.object(text) || length(text) > 1L) {
    return(fail("A custom class parser must receive one character value."))
  }
  warning_text <- NULL
  value <- tryCatch(withCallingHandlers(
    vctrs::vec_cast(text, prototype),
    warning = function(w) {
      warning_text <<- conditionMessage(w)
      invokeRestart("muffleWarning")
    }
  ), error = function(e) e)
  if (inherits(value, "error")) return(fail(conditionMessage(value)))
  if (!is.null(warning_text)) return(fail(warning_text))
  if (length(value) != length(text) || typeof(value) != typeof(prototype) ||
      !identical(class(value), class(prototype)) ||
      !identical(attributes(value), attributes(prototype))) {
    return(fail("The custom vctrs cast changed the prototype type or attributes."))
  }
  list(value = value, error = NULL)
}

table_vctrs_text_cast_capable <- function(x, prototype = NULL) {
  if (!inherits(x, "vctrs_vctr") || !requireNamespace("vctrs", quietly = TRUE)) {
    return(FALSE)
  }
  if (is.null(prototype)) prototype <- table_column_prototype(x)
  cast <- table_vctrs_text_cast(character(), prototype)
  is.null(cast$error) && length(cast$value) == 0L &&
    identical(typeof(cast$value), typeof(prototype)) &&
    identical(class(cast$value), class(prototype)) &&
    identical(attributes(cast$value), attributes(prototype))
}

table_format_extension <- function(x, width = NULL) {
  n <- length(x)
  if (!n) return(character())
  limit <- if (length(width) == 1L && is.numeric(width) && !is.na(width)) {
    max(0L, min(256L, as.integer(width)))
  } else {
    80L
  }

  # Use a class-chain pillar method when one exists. Otherwise call format()
  # directly; pillar's default method is not guaranteed to forward to it.
  # Errors and malformed results are isolated from the table and replaced by
  # compact class labels.
  has_pillar_method <- table_has_s3_method("pillar_shaft", x, "pillar")
  out <- if (has_pillar_method) {
    table_pillar_format(x, limit)
  } else {
    tryCatch(format(x, trim = TRUE), error = function(e) NULL)
  }
  if (!is.character(out) || length(out) != n) {
    out <- rep(paste0("<", table_extension_class_label(x), ">"), n)
  }
  out <- tryCatch(sanitize_text(unclass(out)), error = function(e) NULL)
  if (!is.character(out) || length(out) != n) {
    out <- rep(paste0("<", table_extension_class_label(x), ">"), n)
    out <- sanitize_text(out)
  }
  out[is.na(out)] <- paste0("<", table_extension_class_label(x), ">")
  missing <- tryCatch(table_missing_mask(x), error = function(e) rep(FALSE, n))
  if (is.logical(missing) && length(missing) == n) out[missing & !is.na(missing)] <- "NA"
  if (limit < 256L || any(str_width(out) > limit)) {
    out <- vapply(out, str_truncate, character(1), width = limit, USE.NAMES = FALSE)
  }
  out
}

table_units_label <- function(x) {
  if (!inherits(x, "units")) return("")
  if (!requireNamespace("units", quietly = TRUE)) return("units")
  value <- tryCatch(units::deparse_unit(x), error = function(e) NULL)
  if (length(value) != 1L || is.na(value) || !nzchar(value)) "units" else value
}

table_labelled_storage <- function(x) {
  value <- x
  attributes(value) <- NULL
  value
}

table_labelled_type_code <- function(x) {
  switch(typeof(x), integer = "int", double = "dbl", character = "chr", "obj")
}

table_labelled_valid <- function(x) {
  if (!inherits(x, "haven_labelled") || !requireNamespace("haven", quietly = TRUE) ||
      !is.atomic(x) || is.object(x) && !inherits(x, "haven_labelled")) return(FALSE)
  storage <- table_labelled_storage(x)
  if (!(typeof(storage) %in% c("integer", "double", "character"))) return(FALSE)
  labels <- attr(x, "labels", exact = TRUE)
  if (!is.null(labels)) {
    label_names <- names(labels)
    if (!is.atomic(labels) || typeof(labels) != typeof(storage) ||
        length(label_names) != length(labels) || anyNA(label_names)) return(FALSE)
    if (typeof(labels) == "double" && anyNA(labels) &&
        any(is.na(labels) & !haven::is_tagged_na(labels))) return(FALSE)
  }
  variable_label <- attr(x, "label", exact = TRUE)
  if (!is.null(variable_label) &&
      (!is.character(variable_label) || length(variable_label) != 1L || is.na(variable_label))) return(FALSE)
  if (inherits(x, "haven_labelled_spss")) {
    na_values <- attr(x, "na_values", exact = TRUE)
    na_range <- attr(x, "na_range", exact = TRUE)
    if (!(typeof(storage) %in% c("integer", "double"))) return(FALSE)
    if (!is.null(na_values) && (!is.numeric(na_values) || typeof(na_values) != typeof(storage) || anyNA(na_values))) {
      return(FALSE)
    }
    if (!is.null(na_range) && (!is.numeric(na_range) || length(na_range) != 2L ||
                               anyNA(na_range) || na_range[[1L]] > na_range[[2L]])) return(FALSE)
  } else if (!is.null(attr(x, "na_values", exact = TRUE)) ||
             !is.null(attr(x, "na_range", exact = TRUE))) {
    return(FALSE)
  }
  TRUE
}

table_labelled_editable <- function(x) table_labelled_valid(x)

table_labelled_metadata <- function(x) {
  handler <- table_type_handler(x)
  if (!(handler$id %in% c("labelled", "labelled_spss"))) {
    return(list(base_type = typeof(x), variable_label = NULL, value_labels = NULL,
                na_values = NULL, na_range = NULL, missing_definitions = NULL,
                label_mode = NA_character_))
  }
  labels <- attr(x, "labels", exact = TRUE)
  tagged_labels <- character()
  if (requireNamespace("haven", quietly = TRUE) && is.double(labels) && length(labels)) {
    tagged <- haven::is_tagged_na(labels)
    if (any(tagged)) tagged_labels <- names(labels)[tagged]
  }
  list(
    base_type = typeof(table_labelled_storage(x)),
    variable_label = attr(x, "label", exact = TRUE),
    value_labels = labels,
    na_values = attr(x, "na_values", exact = TRUE),
    na_range = attr(x, "na_range", exact = TRUE),
    missing_definitions = list(
      tagged_na_labels = tagged_labels,
      na_values = attr(x, "na_values", exact = TRUE),
      na_range = attr(x, "na_range", exact = TRUE)
    ),
    label_mode = "raw"
  )
}

table_geometry_type_names <- c(
  "POINT", "MULTIPOINT", "LINESTRING", "POLYGON", "MULTILINESTRING",
  "MULTIPOLYGON", "GEOMETRYCOLLECTION", "GEOMETRY"
)

table_geometry_type_name <- function(x) {
  geometry_type <- intersect(class(x), table_geometry_type_names)
  if (!length(geometry_type) && inherits(x, "sfc")) {
    geometry_type <- intersect(sub("^sfc_", "", class(x)), table_geometry_type_names)
  }
  if (length(geometry_type)) geometry_type[[1L]] else "GEOMETRY"
}

table_geometry_dimension <- function(x) {
  dimensions <- intersect(class(x), c("XY", "XYZ", "XYM", "XYZM"))
  if (length(dimensions)) dimensions[[1L]] else NA_character_
}

table_geometry_crs_label <- function(crs) {
  if (is.null(crs)) return("NA CRS")
  epsg <- tryCatch(crs$epsg, error = function(e) NA_integer_)
  if (length(epsg) == 1L && !is.na(epsg)) return(paste0("EPSG:", epsg))
  input <- tryCatch(crs$input, error = function(e) NA_character_)
  if (length(input) != 1L || is.na(input) || !nzchar(input)) return("NA CRS")
  if (nchar(input, type = "chars") > 32L) return("custom CRS")
  input
}

table_geometry_metadata <- function(x, active = FALSE) {
  handler <- table_type_handler(x)
  is_geometry <- handler$id %in% c("sfc", "sfg", "sfg_list")
  if (!is_geometry) {
    return(list(
      is_geometry = FALSE, geometry_type = "", dimensions = "",
      crs = NULL, crs_label = "", bbox = NULL, precision = NA_real_,
      active = FALSE
    ))
  }

  first_geometry <- NULL
  if (handler$id == "sfc" && length(x)) {
    first_geometry <- tryCatch(x[[1L]], error = function(e) NULL)
  } else if (handler$id == "sfg") {
    first_geometry <- x
  } else if (handler$id == "sfg_list" && length(x)) {
    geometry_rows <- which(vapply(x, inherits, logical(1), "sfg", USE.NAMES = FALSE))
    if (length(geometry_rows)) first_geometry <- tryCatch(x[[geometry_rows[[1L]]]], error = function(e) NULL)
  }

  geometry_type <- if (handler$id == "sfc" && requireNamespace("sf", quietly = TRUE)) {
    value <- tryCatch(as.character(sf::st_geometry_type(x, by_geometry = FALSE)),
                      error = function(e) NULL)
    if (length(value) == 1L && !is.na(value)) value else
      if (!is.null(first_geometry)) table_geometry_type_name(first_geometry) else "GEOMETRY"
  } else if (!is.null(first_geometry)) {
    table_geometry_type_name(first_geometry)
  } else if (handler$id == "sfc") {
    table_geometry_type_name(x)
  } else {
    "GEOMETRY"
  }
  dimensions <- if (!is.null(first_geometry)) table_geometry_dimension(first_geometry) else ""
  if (length(dimensions) != 1L || is.na(dimensions)) dimensions <- ""
  crs <- if (handler$id == "sfc" && requireNamespace("sf", quietly = TRUE)) {
    tryCatch(sf::st_crs(x), error = function(e) attr(x, "crs", exact = TRUE))
  } else if (handler$id == "sfc") {
    attr(x, "crs", exact = TRUE)
  } else {
    NULL
  }
  bbox <- if (handler$id == "sfc" && requireNamespace("sf", quietly = TRUE)) {
    tryCatch(sf::st_bbox(x), error = function(e) attr(x, "bbox", exact = TRUE))
  } else if (handler$id == "sfc") {
    attr(x, "bbox", exact = TRUE)
  } else {
    NULL
  }
  precision <- if (handler$id == "sfc") {
    value <- attr(x, "precision", exact = TRUE)
    if (length(value) == 1L && is.numeric(value)) as.double(value) else NA_real_
  } else {
    NA_real_
  }

  list(
    is_geometry = TRUE,
    geometry_type = geometry_type,
    dimensions = dimensions,
    crs = crs,
    crs_label = table_geometry_crs_label(crs),
    bbox = bbox,
    precision = precision,
    active = isTRUE(active)
  )
}

table_geometry_type_summary <- function(metadata) {
  parts <- c(metadata$geometry_type, metadata$crs_label)
  parts <- parts[!is.na(parts) & nzchar(parts)]
  paste0("sfc [", paste(parts, collapse = ", "), "]")
}

table_column_metadata <- function(x) {
  handler <- table_type_handler(x)
  prototype <- table_column_prototype(x)
  class_value <- class(prototype)
  labelled <- table_labelled_metadata(prototype)
  geometry <- table_geometry_metadata(x)
  list(
    handler = handler,
    class = class_value,
    class_label = if (length(class_value)) paste(class_value, collapse = "/") else "",
    typeof = typeof(prototype),
    prototype = prototype,
    attributes = attributes(prototype),
    base_type = labelled$base_type,
    variable_label = labelled$variable_label,
    value_labels = labelled$value_labels,
    na_values = labelled$na_values,
    na_range = labelled$na_range,
    missing_definitions = labelled$missing_definitions,
    label_mode = labelled$label_mode,
    geometry_metadata = geometry,
    allows_missing = !(handler$id %in% c("unsupported", "raw")),
    type = if (handler$id == "sfc") table_geometry_type_summary(geometry) else table_type_summary(prototype, handler),
    format = if (geometry$is_geometry) "geometry" else if (handler$id %in% c("list", "raw_list", "blob")) "summary" else if (handler$id %in% c("labelled", "labelled_spss")) "labelled" else if (handler$id == "extension") "extension" else if (handler$id %in% c("factor", "ordered", "date", "posixct", "difftime", "hms", "integer64", "units") && requireNamespace("pillar", quietly = TRUE)) "pillar" else "base",
    editable = isTRUE(tryCatch(
      if (handler$id == "extension") handler$editable(x, prototype) else handler$editable(x),
      error = function(e) FALSE
    ))
  )
}

table_geometry_coordinate_count <- function(x) {
  if (is.matrix(x) || is.array(x)) return(as.integer(dim(x)[[1L]]))
  if (is.numeric(x)) {
    if (!length(x) || all(is.na(x))) return(0L)
    return(1L)
  }
  if (is.list(x)) {
    counts <- lapply(x, table_geometry_coordinate_count)
    if (!length(counts)) return(0L)
    total <- sum(as.double(unlist(counts, use.names = FALSE)))
    return(as.integer(min(total, .Machine$integer.max)))
  }
  0L
}

table_geometry_component_count <- function(x) {
  if (!is.list(x)) return(0L)
  length(x)
}

table_geometry_empty <- function(x) {
  if (is.null(x)) return(NA)
  if (!inherits(x, "sfg")) return(NA)
  geometry_type <- table_geometry_type_name(x)
  empty <- switch(
    geometry_type,
    POINT = !length(x) || all(is.na(x)),
    MULTIPOINT = !length(x) || table_geometry_coordinate_count(x) == 0L,
    LINESTRING = !length(x) || table_geometry_coordinate_count(x) == 0L,
    POLYGON = !length(x) || table_geometry_coordinate_count(x) == 0L,
    MULTILINESTRING = !length(x) || table_geometry_coordinate_count(x) == 0L,
    MULTIPOLYGON = !length(x) || table_geometry_coordinate_count(x) == 0L,
    GEOMETRYCOLLECTION = !length(x) || all(vapply(x, table_geometry_empty, logical(1))),
    NULL
  )
  if (!is.null(empty)) return(isTRUE(empty))
  if (requireNamespace("sf", quietly = TRUE)) {
    value <- tryCatch(sf::st_is_empty(x), error = function(e) NA)
    if (length(value) == 1L && !is.na(value)) return(isTRUE(value))
  }
  FALSE
}

table_geometry_wkt <- function(x, max_coordinates = 64L, max_chars = 120L) {
  if (!inherits(x, "sfg")) return("<unavailable>")
  count <- table_geometry_coordinate_count(x)
  if (count > max_coordinates) return(sprintf("<omitted: %s coordinates>", format(count, big.mark = ",")))
  if (requireNamespace("sf", quietly = TRUE)) {
    wkt <- tryCatch(as.character(sf::st_as_text(x, digits = 7L)), error = function(e) NULL)
    if (length(wkt) == 1L && !is.na(wkt)) return(str_truncate(wkt, max_chars))
  }
  if (table_geometry_type_name(x) == "POINT" && is.numeric(x)) {
    return(str_truncate(paste0("POINT (", paste(format(x, trim = TRUE), collapse = " "), ")"), max_chars))
  }
  sprintf("<%s>", table_geometry_type_name(x))
}

table_geometry_cell_format <- function(x, width = NULL) {
  if (is.null(x)) return("<missing geometry>")
  if (!inherits(x, "sfg")) return("<invalid geometry>")
  type <- table_geometry_type_name(x)
  if (isTRUE(table_geometry_empty(x))) {
    out <- paste(type, "EMPTY")
  } else {
    components <- switch(
      type,
      MULTIPOINT = sprintf("%s [%d points]", type, table_geometry_coordinate_count(x)),
      LINESTRING = sprintf("%s [%d coordinates]", type, table_geometry_coordinate_count(x)),
      POLYGON = sprintf("%s [%d rings]", type, table_geometry_component_count(x)),
      MULTILINESTRING = sprintf("%s [%d lines]", type, table_geometry_component_count(x)),
      MULTIPOLYGON = sprintf("%s [%d polygons]", type, table_geometry_component_count(x)),
      GEOMETRYCOLLECTION = sprintf("%s [%d geometries]", type, table_geometry_component_count(x)),
      GEOMETRY = sprintf("%s [%d coordinates]", type, table_geometry_coordinate_count(x)),
      NULL
    )
    out <- if (type == "POINT") table_geometry_wkt(x, max_coordinates = 1L, max_chars = width %||% 120L) else components
    if (is.null(out)) out <- sprintf("<%s>", type)
  }
  if (!is.null(width) && length(width) == 1L && !is.na(width)) {
    out <- str_truncate(out, max(0L, as.integer(width)))
  }
  out
}

table_geometry_format_values <- function(x, width = NULL, handler = table_type_handler(x)) {
  if (handler$id == "sfc") {
    if (!length(x)) return(character())
    return(vapply(seq_along(x), function(i) {
      value <- tryCatch(x[[i]], error = function(e) NULL)
      table_geometry_cell_format(value, width)
    }, character(1), USE.NAMES = FALSE))
  }
  if (handler$id == "sfg") return(table_geometry_cell_format(x, width))
  if (!length(x)) return(character())
  vapply(x, function(value) table_geometry_cell_format(value, width),
         character(1), USE.NAMES = FALSE)
}

table_geometry_details <- function(x, max_chars = 120L) {
  geometry <- if (inherits(x, "sfc")) {
    if (!length(x)) NULL else tryCatch(x[[1L]], error = function(e) NULL)
  } else if (inherits(x, "sfg")) {
    x
  } else {
    NULL
  }
  if (is.null(geometry)) {
    result <- list(
      Type = "GEOMETRY",
      CRS = if (inherits(x, "sfc")) table_geometry_crs_label(attr(x, "crs", exact = TRUE)) else "NA CRS",
      Dimensions = "Unknown", Empty = "Unknown", Coordinates = NA_integer_
    )
    result[["Bounding box"]] <- "Unavailable"
    result[["WKT preview"]] <- "<missing geometry>"
    return(result)
  }
  metadata <- table_geometry_metadata(x)
  empty <- table_geometry_empty(geometry)
  dimensions <- table_geometry_dimension(geometry)
  if (length(dimensions) != 1L || is.na(dimensions)) dimensions <- "Unknown"
  bbox <- if (inherits(x, "sfc") && requireNamespace("sf", quietly = TRUE)) {
    value <- tryCatch(sf::st_bbox(x[1L]), error = function(e) NULL)
    if (is.null(value) || any(!is.finite(value))) "Unavailable" else
      paste(paste(names(value), format(as.numeric(value), trim = TRUE)), collapse = ", ")
  } else {
    "Unavailable"
  }
  result <- list(
    Type = table_geometry_type_name(geometry),
    CRS = metadata$crs_label,
    Dimensions = dimensions,
    Empty = if (is.na(empty)) "Unknown" else if (empty) "Yes" else "No",
    Coordinates = table_geometry_coordinate_count(geometry)
  )
  result[["Bounding box"]] <- bbox
  result[["WKT preview"]] <- table_geometry_wkt(geometry, max_chars = max_chars)
  result
}

table_slice <- function(x, rows) {
  if (requireNamespace("vctrs", quietly = TRUE)) {
    sliced <- tryCatch(vctrs::vec_slice(x, rows), error = function(e) NULL)
    if (!is.null(sliced)) return(sliced)
  }
  x[rows]
}

table_raw_preview <- function(x, width = NULL, max_bytes = 8L) {
  size <- length(x)
  if (!size) {
    out <- "0 bytes"
  } else {
    shown <- min(size, max(0L, as.integer(max_bytes)))
    hex <- if (shown) paste(sprintf("%02X", as.integer(x[seq_len(shown)])), collapse = " ") else ""
    unit <- if (size == 1L) "byte" else "bytes"
    suffix <- if (size > shown) " ..." else ""
    out <- paste0(size, " ", unit, ": ", hex, suffix)
  }
  if (!is.null(width) && length(width) == 1L && !is.na(width)) {
    out <- str_truncate(out, max(0L, as.integer(width)))
  }
  out
}

table_binary_value_summary <- function(value, width = NULL) {
  if (is.null(value)) return("<NULL>")
  if (is.raw(value)) return(table_raw_preview(value, width = width))
  if (is.double(value) && length(value) == 1L && is.nan(value)) return("NaN")
  if (is.atomic(value) && length(value) == 1L && isTRUE(tryCatch(is.na(value), error = function(e) FALSE))) {
    return("NA")
  }
  NULL
}

table_blob_summary <- function(x, width = NULL) {
  if (!length(x)) return(character())
  vapply(seq_along(x), function(i) {
    value <- tryCatch(x[[i]], error = function(e) NULL)
    summary <- table_binary_value_summary(value, width = width)
    if (is.null(summary)) "<invalid blob element>" else summary
  }, character(1), USE.NAMES = FALSE)
}

table_list_summary <- function(x, width = NULL) {
  if (!length(x)) return(character())
  vapply(x, function(value) {
    binary <- table_binary_value_summary(value, width = width)
    if (!is.null(binary)) return(binary)
    if (is.null(value)) return("<NULL>")
    if (is.environment(value)) return("<environment>")
    if (is.function(value)) return("<function>")
    if (is.data.frame(value)) {
      return(sprintf("<%s %d x %d>", if (inherits(value, "tbl_df")) "tibble" else "data.frame",
                     nrow(value), ncol(value)))
    }
    if (is.matrix(value) || is.array(value)) {
      return(sprintf("<%s %s>", typeof(value), paste(dim(value), collapse = " x ")))
    }
    if (is.list(value)) return(sprintf("<list[%d]>", length(value)))
    if (!length(value)) return(sprintf("<%s[0]>", typeof(value)))
    if (length(value) != 1L) return(sprintf("<%s[%d]>", table_type_summary(value), length(value)))
    out <- tryCatch(table_format_values(value, width = width), error = function(e) NULL)
    if (is.null(out) || !length(out) || is.na(out[[1L]])) {
      if (is.atomic(value) && length(value) == 1L && isTRUE(table_missing_mask(value)[[1L]])) return("NA")
      return(sprintf("<%s>", table_type_summary(value)))
    }
    out[[1L]]
  }, character(1), USE.NAMES = FALSE)
}

table_pillar_format <- function(x, width = NULL) {
  if (!requireNamespace("pillar", quietly = TRUE)) return(NULL)
  shaft <- tryCatch(pillar::pillar_shaft(x), error = function(e) NULL)
  if (is.null(shaft)) return(NULL)
  out <- tryCatch({
    if (is.null(width)) format(shaft) else format(shaft, width = max(1L, as.integer(width)))
  }, error = function(e) NULL)
  if (is.null(out)) NULL else tryCatch(as.character(out), error = function(e) NULL)
}

table_labelled_is_tagged_na <- function(x) {
  if (!requireNamespace("haven", quietly = TRUE) || typeof(x) != "double") {
    return(rep(FALSE, length(x)))
  }
  tryCatch(haven::is_tagged_na(x), error = function(e) rep(FALSE, length(x)))
}

table_labelled_tag <- function(x) {
  if (!requireNamespace("haven", quietly = TRUE) || typeof(x) != "double") {
    return(rep(NA_character_, length(x)))
  }
  tryCatch(haven::na_tag(x), error = function(e) rep(NA_character_, length(x)))
}

table_labelled_label_matches <- function(x, value, tagged = FALSE, tag = NA_character_) {
  labels <- attr(x, "labels", exact = TRUE)
  if (is.null(labels) || !is.atomic(labels) || typeof(labels) != typeof(x) ||
      !length(labels) || is.null(names(labels))) return(integer())
  label_values <- table_labelled_storage(labels)
  if (tagged && typeof(labels) == "double" && requireNamespace("haven", quietly = TRUE)) {
    label_tagged <- haven::is_tagged_na(labels)
    label_tags <- haven::na_tag(labels)
    return(which(label_tagged & !is.na(label_tags) & label_tags == tag))
  }
  if (length(value) != 1L || is.na(value)) return(integer())
  which(!is.na(label_values) & label_values == value)
}

table_labelled_scalar_equal <- function(x, y) {
  if (length(x) != 1L || length(y) != 1L || typeof(x) != typeof(y)) return(FALSE)
  x_tagged <- table_labelled_is_tagged_na(x)[[1L]]
  y_tagged <- table_labelled_is_tagged_na(y)[[1L]]
  if (x_tagged || y_tagged) {
    return(x_tagged && y_tagged && identical(table_labelled_tag(x)[[1L]], table_labelled_tag(y)[[1L]]))
  }
  if (is.na(x) || is.na(y)) return(is.na(x) && is.na(y) && identical(is.nan(x), is.nan(y)))
  identical(unname(x), unname(y))
}

table_labelled_raw_text <- function(x, width = NULL) {
  table_format_values(table_labelled_storage(x), width = width)
}

table_format_labelled <- function(x, width = NULL, label_mode = "raw") {
  raw <- table_labelled_storage(x)
  out <- table_labelled_raw_text(x, width = width)
  if (!requireNamespace("haven", quietly = TRUE)) return(out)
  tagged <- table_labelled_is_tagged_na(x)
  tags <- table_labelled_tag(x)
  if (length(tagged) == length(out) && length(tags) == length(out)) {
    out[tagged] <- paste0("NA(", tags[tagged], ")")
  }
  sp_missing <- rep(FALSE, length(out))
  if (inherits(x, "haven_labelled_spss")) {
    sp_missing <- tryCatch(is.na(x) & !is.na(raw), error = function(e) rep(FALSE, length(out)))
    if (length(sp_missing) != length(out)) sp_missing <- rep(FALSE, length(out))
  }
  if (label_mode == "labels") {
    for (i in seq_along(out)) {
      matches <- table_labelled_label_matches(x, raw[[i]], tagged = tagged[[i]], tag = tags[[i]])
      label_names <- unique(names(attr(x, "labels", exact = TRUE))[matches])
      label_names <- label_names[!is.na(label_names)]
      if (length(label_names)) {
        out[[i]] <- paste0(paste(label_names, collapse = " / "), " [", out[[i]], "]")
      }
    }
  }
  if (any(sp_missing)) out[sp_missing] <- paste0(out[sp_missing], " (SPSS missing)")
  out
}

table_format_values <- function(x, width = NULL, label_mode = "raw") {
  label_mode <- match.arg(label_mode, c("raw", "labels"))
  handler <- table_type_handler(x)
  if (handler$id == "blob") return(table_blob_summary(x, width))
  if (handler$id %in% c("sfc", "sfg", "sfg_list")) {
    return(table_geometry_format_values(x, width, handler))
  }
  if (handler$id %in% c("extension", "unsupported")) {
    return(table_format_extension(x, width))
  }
  if (handler$id == "raw") {
    if (!length(x)) return(character())
    return(vapply(seq_along(x), function(i) table_raw_preview(x[i], width), character(1), USE.NAMES = FALSE))
  }
  if (is.list(x)) return(table_list_summary(x, width))
  if (identical(handler$id, "integer64") && !requireNamespace("bit64", quietly = TRUE)) {
    return(rep("<integer64: install bit64 to inspect>", length(x)))
  }
  if (handler$id == "units") {
    if (!requireNamespace("units", quietly = TRUE)) {
      out <- tryCatch(format(x, trim = TRUE), error = function(e) NULL)
      if (!is.null(out) && length(out) == length(x)) return(as.character(out))
      return(rep("<units: install units to inspect>", length(x)))
    }
    values <- tryCatch(units::drop_units(x), error = function(e) NULL)
    if (is.null(values) || length(values) != length(x)) {
      return(rep(paste0("<", table_units_label(x), ">"), length(x)))
    }
    return(table_format_values(values, width = width))
  }
  if (handler$id %in% c("labelled", "labelled_spss")) {
    return(table_format_labelled(x, width = width, label_mode = label_mode))
  }
  if (handler$id %in% c("factor", "ordered", "date", "posixct", "difftime", "hms", "integer64")) {
    out <- table_pillar_format(x, width)
    if (is.null(out)) out <- tryCatch(format(x, trim = TRUE), error = function(e) NULL)
    if (is.null(out) || length(out) != length(x)) {
      out <- rep(paste0("<", handler$type, ">"), length(x))
    }
    missing <- tryCatch(table_missing_mask(x), error = function(e) rep(FALSE, length(x)))
    if (length(missing) == length(out)) {
      if (is.double(x) && handler$id != "integer64") missing[is.nan(x)] <- FALSE
      out[missing] <- "NA"
    }
    return(as.character(out))
  }
  if (is.double(x)) {
    sample <- x[sample_rows(length(x))]
    digits <- decimals_needed(sample[is.finite(sample)])
    out <- trimws(formatC(x, format = "f", digits = digits))
    missing <- is.na(x) & !is.nan(x)
    out[missing] <- "NA"
    out[is.nan(x)] <- "NaN"
    return(out)
  }
  out <- as.character(x)
  missing <- tryCatch(table_missing_mask(x), error = function(e) rep(FALSE, length(x)))
  if (length(missing) == length(out)) out[missing] <- "NA"
  out
}

table_missing_mask <- function(x) {
  if (is.raw(x)) return(rep(FALSE, length(x)))
  if (inherits(x, "sfc")) {
    missing <- tryCatch(is.na(x), error = function(e) NULL)
    if (!is.null(missing) && length(missing) == length(x)) return(missing)
    return(rep(FALSE, length(x)))
  }
  if (is.list(x)) {
    return(vapply(x, function(value) {
      if (is.null(value)) return(TRUE)
      if (!is.atomic(value) || length(value) != 1L) return(FALSE)
      tryCatch(isTRUE(is.na(value)[[1L]]), error = function(e) FALSE)
    }, logical(1), USE.NAMES = FALSE))
  }
  missing <- tryCatch(is.na(x), error = function(e) NULL)
  if (!is.logical(missing) || length(missing) != length(x)) {
    return(rep(FALSE, length(x)))
  }
  missing[is.na(missing)] <- FALSE
  missing
}

table_edit_text <- function(x) {
  if (length(x) != 1L) return("")
  handler <- table_type_handler(x)
  if (handler$id %in% c("raw", "blob", "raw_list", "sfc", "sfg", "sfg_list", "list", "unsupported")) return("")
  if (handler$id %in% c("labelled", "labelled_spss")) {
    if (table_labelled_is_tagged_na(x)[[1L]]) {
      return(paste0("NA(", table_labelled_tag(x)[[1L]], ")"))
    }
    raw <- table_labelled_storage(x)
    if (is.nan(raw)) return("NaN")
    if (is.na(raw)) return("NA")
    if (typeof(raw) == "character") return(paste0("raw:", raw))
    if (is.infinite(raw)) return(paste0("raw:", if (raw > 0) "Inf" else "-Inf"))
    return(paste0("raw:", if (typeof(raw) == "integer") as.character(raw) else sprintf("%.17g", raw)))
  }
  if (handler$id == "units") {
    if (!requireNamespace("units", quietly = TRUE)) return("")
    value <- tryCatch(as.double(units::drop_units(x)), error = function(e) NA_real_)
    if (is.nan(value)) return("NaN")
    if (is.na(value)) return("")
    if (is.infinite(value)) return(if (value > 0) "Inf" else "-Inf")
    return(sprintf("%.17g", value))
  }
  missing <- tryCatch(isTRUE(table_missing_mask(x)[[1L]]), error = function(e) FALSE)
  if (missing && !(is.double(x) && is.nan(x))) return("")
  if (handler$id == "integer64") return(as.character(x))
  if (handler$id == "double") {
    if (is.nan(x)) return("NaN")
    if (is.infinite(x)) return(if (x > 0) "Inf" else "-Inf")
    return(sprintf("%.17g", x))
  }
  if (handler$id == "date") return(format(x, format = "%Y-%m-%d"))
  if (handler$id == "posixct") {
    tz <- table_posix_timezone(x)
    local <- format(x, format = "%Y-%m-%d %H:%M:%OS", tz = tz, usetz = FALSE)
    wall <- tryCatch(as.POSIXct(local, tz = "UTC", format = "%Y-%m-%d %H:%M:%OS"), error = function(e) as.POSIXct(NA, tz = "UTC"))
    if (is.na(wall)) return(local)
    offset <- round(as.numeric(wall) - as.numeric(x))
    sign <- if (offset < 0) "-" else "+"
    offset <- abs(offset)
    hours <- floor(offset / 3600)
    minutes <- floor((offset - hours * 3600) / 60)
    return(paste0(local, sign, sprintf("%02d%02d", hours, minutes)))
  }
  if (handler$id == "difftime") {
    units <- attr(x, "units") %||% "secs"
    return(sprintf("%.17g", as.numeric(x, units = units)))
  }
  if (handler$id == "hms") return(table_hms_text(as.numeric(x, units = "secs")))
  as.character(x)
}

table_posix_timezone <- function(x) {
  tz <- attr(x, "tzone")
  if (is.character(tz) && length(tz) && !is.na(tz[[1L]]) && nzchar(tz[[1L]])) return(tz[[1L]])
  current <- tryCatch(Sys.timezone(), error = function(e) "UTC")
  if (is.character(current) && length(current) && !is.na(current[[1L]]) && nzchar(current[[1L]])) current[[1L]] else "UTC"
}

table_hms_text <- function(seconds) {
  if (is.na(seconds)) return("")
  sign <- if (seconds < 0) "-" else ""
  seconds <- abs(seconds)
  hours <- floor(seconds / 3600)
  minutes <- floor((seconds - hours * 3600) / 60)
  secs <- seconds - hours * 3600 - minutes * 60
  sec_text <- format(secs, digits = 15L, scientific = FALSE, trim = TRUE)
  if (secs < 10) sec_text <- paste0("0", sec_text)
  paste0(sign, sprintf("%02.0f:%02.0f:", hours, minutes), sec_text)
}

table_number <- function(text) {
  fail <- function(message) list(value = NULL, error = message)
  if (!grepl("^[+-]?(?:[0-9]+(?:\\.[0-9]*)?|\\.[0-9]+)(?:[eE][+-]?[0-9]+)?$", text, perl = TRUE)) {
    special <- switch(tolower(text), nan = NaN, inf = Inf, `+inf` = Inf, `-inf` = -Inf, NULL)
    if (is.null(special)) return(fail("Enter a number using a period as the decimal separator."))
    return(list(value = special, error = NULL))
  }
  warning_text <- NULL
  value <- tryCatch(withCallingHandlers(as.double(text), warning = function(w) {
    warning_text <<- conditionMessage(w)
    invokeRestart("muffleWarning")
  }), error = function(e) NA_real_)
  if (is.na(value) || is.infinite(value) || !is.null(warning_text)) {
    return(fail("The number is outside the supported double range."))
  }
  list(value = value, error = NULL)
}

table_parse_cell <- function(text, metadata) {
  if (is.character(text)) return(table_parse_text(text, metadata))
  table_cast_cell(text, metadata)
}

table_units_convert <- function(x, target) {
  if (!requireNamespace("units", quietly = TRUE)) {
    return(list(value = NULL, error = "Editing units columns requires the optional units package."))
  }
  warning_text <- NULL
  value <- tryCatch(withCallingHandlers(
    units::set_units(x, target, mode = "standard"),
    warning = function(w) {
      warning_text <<- conditionMessage(w)
      invokeRestart("muffleWarning")
    }
  ), error = function(e) e)
  if (inherits(value, "error")) {
    return(list(value = NULL, error = conditionMessage(value)))
  }
  if (!is.null(warning_text)) return(list(value = NULL, error = warning_text))
  if (inherits(x, "units")) {
    source_values <- tryCatch(as.double(units::drop_units(x)), error = function(e) NULL)
    target_values <- tryCatch(as.double(units::drop_units(value)), error = function(e) NULL)
    if (is.null(source_values) || is.null(target_values) || length(source_values) != length(target_values)) {
      return(list(value = NULL, error = "The unit conversion did not preserve the value shape."))
    }
    finite <- is.finite(source_values)
    if (any(finite & !is.finite(target_values))) {
      return(list(value = NULL, error = "The unit conversion is outside the supported double range."))
    }
    back_warning <- NULL
    back <- tryCatch(withCallingHandlers(
      units::set_units(value, base::units(x), mode = "standard"),
      warning = function(w) {
        back_warning <<- conditionMessage(w)
        invokeRestart("muffleWarning")
      }
    ), error = function(e) e)
    if (inherits(back, "error")) return(list(value = NULL, error = conditionMessage(back)))
    if (!is.null(back_warning)) return(list(value = NULL, error = back_warning))
    back_values <- tryCatch(as.double(units::drop_units(back)), error = function(e) NULL)
    if (is.null(back_values) || length(back_values) != length(source_values)) {
      return(list(value = NULL, error = "The unit conversion could not be checked for precision."))
    }
    finite <- finite & is.finite(back_values)
    if (any(is.finite(source_values) & !is.finite(back_values))) {
      return(list(value = NULL, error = "The unit conversion is outside the supported double range."))
    }
    tolerance <- 32 * .Machine$double.eps * pmax(abs(source_values), abs(back_values))
    if (any(finite & abs(back_values - source_values) > tolerance)) {
      return(list(value = NULL, error = "The unit conversion loses precision beyond double round-trip tolerance."))
    }
  }
  list(value = value, error = NULL)
}

table_parse_units <- function(text, template) {
  fail <- function(message) list(value = NULL, error = message)
  if (!requireNamespace("units", quietly = TRUE)) {
    return(fail("Editing units columns requires the optional units package."))
  }
  if (length(text) != 1L) return(fail("Enter a single measurement."))
  if (is.na(text)) return(list(value = table_na_value(template), error = NULL))
  text <- trimws(text)
  if (!nzchar(text) || toupper(text) == "NA") {
    return(list(value = table_na_value(template), error = NULL))
  }
  numeric_pattern <- "[+-]?(?:(?:[0-9]+(?:\\.[0-9]*)?|\\.[0-9]+)(?:[eE][+-]?[0-9]+)?|NaN|Inf)"
  match <- regexec(paste0("^(", numeric_pattern, ")(?:\\s+(.+))?$"),
                   text, perl = TRUE, ignore.case = TRUE)
  parts <- regmatches(text, match)[[1L]]
  if (!length(parts)) {
    return(fail("Enter a number, optionally followed by a compatible unit."))
  }
  number <- table_number(parts[[2L]])
  if (!is.null(number$error)) return(number)
  unit_text <- if (length(parts) >= 3L) trimws(parts[[3L]]) else ""
  value <- number$value
  if (nzchar(unit_text)) {
    supplied <- table_units_convert(value, unit_text)
    if (!is.null(supplied$error)) {
      return(fail(paste0("Invalid or unsupported unit: ", supplied$error)))
    }
    value <- supplied$value
  }
  converted <- table_units_convert(value, base::units(template))
  if (!is.null(converted$error)) {
    return(fail(paste0("The supplied unit is incompatible with this column: ",
                       converted$error)))
  }
  if (length(converted$value) != 1L) return(fail("Enter a single measurement."))
  list(value = converted$value, error = NULL)
}

table_na_value <- function(template) {
  handler <- table_type_handler(template)
  switch(handler$id,
    logical = NA,
    integer = NA_integer_,
    double = NA_real_,
    character = NA_character_,
    factor = factor(NA_character_, levels = levels(template)),
    ordered = ordered(NA_character_, levels = levels(template)),
    date = structure(NA_real_, class = class(template)),
    posixct = structure(NA_real_, class = class(template), tzone = attr(template, "tzone")),
    difftime = structure(NA_real_, class = class(template), units = attr(template, "units")),
    hms = structure(NA_real_, class = class(template), units = attr(template, "units")),
    integer64 = if (requireNamespace("bit64", quietly = TRUE)) bit64::as.integer64(NA_character_) else NULL,
    units = if (requireNamespace("units", quietly = TRUE)) {
      converted <- table_units_convert(NA_real_, base::units(template))
      converted$value
    } else NULL,
    NULL
  )
}

table_parse_integer <- function(text) {
  parsed <- table_number(text)
  if (!is.null(parsed$error)) return(list(value = NULL, error = "Enter a number that is a whole number within the R integer range."))
  value <- parsed$value
  if (!is.finite(value) || value != trunc(value) || value < -.Machine$integer.max || value > .Machine$integer.max) {
    return(list(value = NULL, error = "Enter a number that is a whole number within the R integer range."))
  }
  list(value = as.integer(value), error = NULL)
}

table_parse_date <- function(text) {
  if (!grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", text)) return(list(value = NULL, error = "Enter a date as YYYY-MM-DD."))
  value <- tryCatch(as.Date(text, format = "%Y-%m-%d"), error = function(e) as.Date(NA))
  if (is.na(value) || !identical(format(value, "%Y-%m-%d"), text)) {
    return(list(value = NULL, error = "Enter a real date as YYYY-MM-DD."))
  }
  list(value = value, error = NULL)
}

table_parse_posixct <- function(text, template) {
  fail <- function(message) list(value = NULL, error = message)
  text <- chartr("T", " ", trimws(text))
  text <- sub(" ([+-][0-9]{2}:?[0-9]{2})$", "\\1", text)
  if (!grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}(\\.[0-9]+)?(Z|[+-][0-9]{2}:?[0-9]{2})?$", text)) {
    return(fail("Enter a timestamp as YYYY-MM-DD HH:MM:SS, optionally with fractional seconds or a UTC offset."))
  }
  suffix <- regmatches(text, regexpr("(Z|[+-][0-9]{2}:?[0-9]{2})$", text))
  has_offset <- length(suffix) > 0L && nzchar(suffix)
  if (has_offset) {
    local <- substr(text, 1L, nchar(text) - nchar(suffix))
    wall <- tryCatch(as.POSIXct(local, tz = "UTC", format = "%Y-%m-%d %H:%M:%OS"), error = function(e) as.POSIXct(NA, tz = "UTC"))
    if (is.na(wall) || !identical(format(wall, tz = "UTC", format = "%Y-%m-%d %H:%M:%S"), substr(local, 1L, 19L))) {
      return(fail("Enter a real timestamp."))
    }
    if (suffix != "Z") {
      digits <- gsub(":", "", substring(suffix, 2L), fixed = TRUE)
      hours <- as.integer(substr(digits, 1L, 2L))
      minutes <- as.integer(substr(digits, 3L, 4L))
      if (is.na(hours) || is.na(minutes) || hours > 23L || minutes > 59L) return(fail("Enter a valid UTC offset."))
      sign <- if (substr(suffix, 1L, 1L) == "+") 1 else -1
      wall <- wall - sign * (hours * 3600 + minutes * 60)
    }
    value <- as.numeric(wall)
  } else {
    tz <- table_posix_timezone(template)
    local <- tryCatch(strptime(text, format = "%Y-%m-%d %H:%M:%OS", tz = tz), error = function(e) NULL)
    if (is.null(local) || is.na(local)) return(fail("Enter a real local timestamp."))
    parsed <- tryCatch(as.POSIXct(local, tz = tz), error = function(e) as.POSIXct(NA, tz = tz))
    if (is.na(parsed)) return(fail("Enter a real local timestamp."))
    expected <- substr(text, 1L, 19L)
    roundtrip <- format(parsed, tz = tz, format = "%Y-%m-%d %H:%M:%S")
    if (!identical(roundtrip, expected)) return(fail("That local time does not exist in the column time zone."))
    nearby <- parsed + seq(-3 * 3600, 3 * 3600, by = 15 * 60)
    same_wall_time <- format(nearby, tz = tz, format = "%Y-%m-%d %H:%M:%S") == expected
    if (sum(same_wall_time, na.rm = TRUE) > 1L) return(fail("That local time is ambiguous in the column time zone; enter an explicit UTC offset."))
    value <- as.numeric(parsed)
  }
  value <- structure(value, class = class(template), tzone = attr(template, "tzone"))
  list(value = value, error = NULL)
}

table_parse_hms <- function(text, template) {
  if (!nzchar(text) || toupper(text) == "NA") return(list(value = table_na_value(template), error = NULL))
  match <- regexec("^([+-])?([0-9]{1,6}):([0-5][0-9]):([0-5][0-9](?:\\.[0-9]+)?)$", text, perl = TRUE)
  parts <- regmatches(text, match)[[1L]]
  if (!length(parts)) return(list(value = NULL, error = "Enter a time as HH:MM:SS."))
  sign <- if (identical(parts[[2L]], "-")) -1 else 1
  seconds <- sign * (as.double(parts[[3L]]) * 3600 + as.double(parts[[4L]]) * 60 + as.double(parts[[5L]]))
  list(value = structure(seconds, class = class(template), units = attr(template, "units")), error = NULL)
}

table_parse_difftime <- function(text, template) {
  parsed <- table_number(text)
  if (!is.null(parsed$error)) return(parsed)
  units <- attr(template, "units") %||% "secs"
  value <- tryCatch(as.difftime(parsed$value, units = units), error = function(e) NULL)
  if (is.null(value)) return(list(value = NULL, error = "Enter a duration in the column's units."))
  list(value = structure(as.numeric(value, units = units), class = class(template), units = units), error = NULL)
}

table_parse_integer64 <- function(text) {
  if (!requireNamespace("bit64", quietly = TRUE)) {
    return(list(value = NULL, error = "Editing integer64 values requires the optional bit64 package."))
  }
  if (!grepl("^[+-]?[0-9]+$", text)) return(list(value = NULL, error = "Enter a whole 64-bit integer."))
  warning_text <- NULL
  value <- tryCatch(withCallingHandlers(bit64::as.integer64(text), warning = function(w) {
    warning_text <<- conditionMessage(w)
    invokeRestart("muffleWarning")
  }), error = function(e) NULL)
  digits <- sub("^[+-]", "", text)
  digits <- sub("^0+", "", digits)
  expected <- if (!nzchar(digits)) "0" else paste0(if (startsWith(text, "-")) "-" else "", digits)
  rendered <- if (is.null(value)) NA_character_ else tryCatch(as.character(value), error = function(e) NA_character_)
  if (is.null(value) || length(value) != 1L || is.na(value) || !is.null(warning_text) ||
      length(rendered) != 1L || is.na(rendered) || !identical(rendered, expected)) {
    return(list(value = NULL, error = "The value is outside the supported integer64 range."))
  }
  list(value = value, error = NULL)
}

table_labelled_raw_value <- function(text, metadata) {
  type <- metadata$typeof
  if (type == "integer") return(table_parse_integer(text))
  if (type == "double") return(table_number(text))
  if (type == "character") return(list(value = text, error = NULL))
  list(value = NULL, error = "This labelled storage type cannot be edited safely.")
}

table_labelled_wrap_scalar <- function(value, metadata) {
  if (length(value) != 1L || !is.atomic(value) || typeof(value) != metadata$typeof) {
    return(list(value = NULL, error = sprintf("Enter one raw value with storage type %s.", metadata$base_type)))
  }
  if (!table_labelled_valid(metadata$prototype)) {
    return(list(value = NULL, error = "This labelled column has invalid metadata and is read-only."))
  }
  wrapped <- tryCatch({
    # Restore only from a validated zero-length prototype. The source vector is
    # never modified, and assignment below verifies the full attribute set.
    attributes(value) <- metadata$attributes
    value
  }, error = function(e) e)
  if (inherits(wrapped, "error") || !identical(typeof(wrapped), metadata$typeof) ||
      !identical(class(wrapped), metadata$class) || !identical(attributes(wrapped), metadata$attributes)) {
    return(list(value = NULL, error = "The raw value cannot be wrapped without changing labelled metadata."))
  }
  list(value = wrapped, error = NULL)
}

table_labelled_input_value <- function(text, metadata) {
  labels <- metadata$value_labels
  if (is.null(labels) || !length(labels) || is.null(names(labels))) return(integer())
  which(names(labels) == text)
}

table_labelled_resolve_label <- function(text, metadata) {
  indexes <- table_labelled_input_value(text, metadata)
  if (!length(indexes)) return(list(value = NULL, error = "Unknown value label."))
  label_values <- table_labelled_storage(metadata$value_labels)[indexes]
  same <- all(vapply(seq_along(label_values)[-1L], function(i) {
    table_labelled_scalar_equal(label_values[[1L]], label_values[[i]])
  }, logical(1)))
  if (!same) return(list(value = NULL, error = "This value label is ambiguous; use `raw:<value>` to choose an underlying value."))
  list(value = label_values[[1L]], error = NULL)
}

table_parse_labelled <- function(text, metadata) {
  fail <- function(message) list(value = NULL, error = message)
  if (!isTRUE(metadata$editable)) {
    return(fail(sprintf("Values of type %s are read-only.", metadata$class_label)))
  }
  if (length(text) != 1L || is.na(text)) return(fail("Enter one labelled value."))

  raw_input <- startsWith(text, "raw:")
  label_input <- startsWith(text, "label:")
  input <- if (raw_input) substring(text, 5L) else if (label_input) substring(text, 7L) else text
  if (!raw_input && !label_input && identical(text, "NA")) {
    missing <- switch(metadata$typeof, integer = NA_integer_, double = NA_real_, character = NA_character_)
    return(table_labelled_wrap_scalar(missing, metadata))
  }
  if (!raw_input && !label_input && identical(text, "NaN")) {
    if (metadata$typeof != "double") return(fail("NaN is only valid in a double labelled column."))
    return(table_labelled_wrap_scalar(NaN, metadata))
  }
  if (!raw_input && !label_input && grepl("^NA\\(", text)) {
    match <- regexec("^NA\\(([A-Za-z])\\)$", text, perl = TRUE)
    parts <- regmatches(text, match)[[1L]]
    if (!length(parts) || metadata$typeof != "double") {
      return(fail("Tagged missing values use `NA(a)` through `NA(z)` in double labelled columns."))
    }
    tag <- tolower(parts[[2L]])
    tagged <- tryCatch(haven::tagged_na(tag), error = function(e) NULL)
    if (is.null(tagged)) return(fail("The tagged NA must use one letter from a to z."))
    return(table_labelled_wrap_scalar(tagged, metadata))
  }

  explicit_label <- label_input
  label_text <- if (label_input) input else text
  resolved_label <- if (raw_input) list(value = NULL, error = "") else
    table_labelled_resolve_label(label_text, metadata)
  if (explicit_label) {
    if (!is.null(resolved_label$error) && nzchar(resolved_label$error)) return(fail(resolved_label$error))
    return(table_labelled_wrap_scalar(resolved_label$value, metadata))
  }

  if (metadata$typeof == "character") {
    if (!raw_input && is.null(resolved_label$error)) {
      return(table_labelled_wrap_scalar(resolved_label$value, metadata))
    }
    if (!raw_input) {
      return(fail("Unknown value label; enter a raw character value as `raw:<value>`."))
    }
    return(table_labelled_wrap_scalar(input, metadata))
  }

  raw_text <- trimws(input)
  raw_value <- table_labelled_raw_value(raw_text, metadata)
  if (raw_input) {
    if (!is.null(raw_value$error)) return(fail(raw_value$error))
    return(table_labelled_wrap_scalar(raw_value$value, metadata))
  }
  if (grepl("ambiguous", resolved_label$error %||% "", fixed = TRUE)) {
    return(fail(resolved_label$error))
  }
  if (is.null(resolved_label$error)) {
    if (is.null(raw_value$error) && !table_labelled_scalar_equal(raw_value$value, resolved_label$value)) {
      return(fail("This input is both a raw value and a different value label; use `raw:` or `label:` explicitly."))
    }
    return(table_labelled_wrap_scalar(resolved_label$value, metadata))
  }
  if (is.null(raw_value$error)) return(table_labelled_wrap_scalar(raw_value$value, metadata))
  fail(resolved_label$error)
}

table_parse_extension <- function(text, metadata) {
  fail <- function(message) list(value = NULL, error = message)
  if (!isTRUE(metadata$editable)) {
    return(fail(sprintf("Values of type %s are read-only.", metadata$class_label %||% "object")))
  }
  if (length(text) != 1L) return(fail("Enter one value for this custom class."))
  parsed <- table_vctrs_text_cast(text, metadata$prototype)
  if (!is.null(parsed$error)) {
    return(fail(sprintf("The custom class rejected this value: %s", parsed$error)))
  }
  parsed
}

table_cast_labelled <- function(value, metadata) {
  fail <- function(message) list(value = NULL, error = message)
  if (!isTRUE(metadata$editable)) return(fail("This labelled column is read-only."))
  if (length(value) != 1L || !is.atomic(value)) return(fail("Enter one scalar labelled value."))
  if (is.object(value)) {
    if (!identical(class(value), metadata$class) || !identical(attributes(value), metadata$attributes)) {
      return(fail("A direct labelled value must have the column's exact class and metadata."))
    }
    value <- table_labelled_storage(value)
  }
  wrapped <- table_labelled_wrap_scalar(value, metadata)
  if (!is.null(wrapped$error)) return(wrapped)
  list(value = wrapped$value, error = NULL)
}

table_parse_text <- function(text, metadata) {
  fail <- function(message) list(value = NULL, error = message)
  if (length(text) != 1L) return(fail("Enter a single value."))
  handler <- metadata$handler
  id <- handler$id
  if (id == "units") return(table_parse_units(text, metadata$prototype))
  if (id %in% c("labelled", "labelled_spss")) return(table_parse_labelled(text, metadata))
  if (id == "extension") return(table_parse_extension(text, metadata))
  if (id %in% c("raw", "blob", "raw_list", "sfc", "sfg", "sfg_list", "list", "unsupported")) {
    return(fail(sprintf("Values of type %s are read-only.", metadata$class_label %||% id)))
  }
  if (is.na(text)) {
    if (id == "character") return(list(value = NA_character_, error = NULL))
    return(fail("Enter a non-missing value or use the text NA."))
  }
  if (id == "character") return(list(value = sanitize_text(text), error = NULL))
  if (id %in% c("unsupported", "sfc", "sfg", "sfg_list", "list")) return(fail(sprintf("Values of type %s are read-only.", metadata$class_label %||% id)))
  if (!(id %in% c("factor", "ordered"))) text <- trimws(text)
  is_missing <- !nzchar(text) || toupper(text) == "NA"
  if (id == "factor" || id == "ordered") {
    if (!nzchar(text) || (toupper(text) == "NA" && !("NA" %in% levels(metadata$prototype)))) {
      return(list(value = table_na_value(metadata$prototype), error = NULL))
    }
    if (!(text %in% levels(metadata$prototype))) {
      return(fail(paste0("Must be one of: ", paste(utils::head(levels(metadata$prototype), 6L), collapse = ", "),
                    if (nlevels(metadata$prototype) > 6L) ", ...")))
    }
    return(list(value = if (id == "ordered") ordered(text, levels = levels(metadata$prototype)) else factor(text, levels = levels(metadata$prototype)), error = NULL))
  }
  if (is_missing) return(list(value = table_na_value(metadata$prototype), error = NULL))
  if (id == "logical") {
    value <- switch(tolower(text), `true` = , t = , yes = , y = , `1` = TRUE, `false` = , f = , no = , n = , `0` = FALSE, NULL)
    if (is.null(value)) return(fail("Enter TRUE or FALSE."))
    return(list(value = value, error = NULL))
  }
  if (id == "integer") return(table_parse_integer(text))
  if (id == "double") return(table_number(text))
  if (id == "date") return(table_parse_date(text))
  if (id == "posixct") return(table_parse_posixct(text, metadata$prototype))
  if (id == "difftime") return(table_parse_difftime(text, metadata$prototype))
  if (id == "hms") return(table_parse_hms(text, metadata$prototype))
  if (id == "integer64") return(table_parse_integer64(text))
  fail(sprintf("Values of type %s are read-only.", metadata$class_label %||% id))
}

table_cast_cell <- function(value, metadata) {
  fail <- function(message) list(value = NULL, error = message)
  handler <- metadata$handler
  id <- handler$id
  if (!isTRUE(metadata$editable)) return(fail(sprintf("Values of type %s are read-only.", metadata$class_label %||% id)))
  if (length(value) != 1L) return(fail("Enter a single value."))
  if (id %in% c("labelled", "labelled_spss")) return(table_cast_labelled(value, metadata))
  if (id == "units") {
    if (!requireNamespace("units", quietly = TRUE)) {
      return(fail("Editing units columns requires the optional units package."))
    }
    converted <- table_units_convert(value, base::units(metadata$prototype))
    if (!is.null(converted$error)) {
      return(fail(paste0("The value is not a compatible units measurement: ",
                         converted$error)))
    }
    value <- converted$value
  }
  if (requireNamespace("vctrs", quietly = TRUE)) {
    cast <- tryCatch(vctrs::vec_cast(value, metadata$prototype), error = function(e) e)
    if (inherits(cast, "error")) return(fail(sprintf("The value does not fit a %s column: %s", metadata$class_label, conditionMessage(cast))))
    return(list(value = cast, error = NULL))
  }
  ok <- switch(id,
    logical = is.logical(value) && !is.object(value),
    integer = (is.integer(value) || (is.double(value) && !is.object(value) && is.finite(value) && value == trunc(value) && value >= -.Machine$integer.max && value <= .Machine$integer.max)),
    double = is.numeric(value) && !is.object(value),
    character = is.character(value) && !is.object(value),
    factor = is.factor(value) || is.character(value),
    ordered = is.ordered(value) || is.character(value),
    date = inherits(value, "Date"),
    posixct = inherits(value, "POSIXct"),
    difftime = inherits(value, "difftime"),
    hms = inherits(value, "hms"),
    integer64 = inherits(value, "integer64"),
    units = inherits(value, "units") && identical(class(value), metadata$class) &&
      identical(attributes(value), metadata$attributes),
    FALSE
  )
  if (!ok) return(fail(sprintf("The value does not fit a %s column.", metadata$class_label)))
  if (id == "integer" && is.double(value)) value <- as.integer(value)
  if (id %in% c("factor", "ordered")) {
    label <- as.character(value)
    if (!is.na(label) && !(label %in% levels(metadata$prototype))) return(fail("The value is not an existing factor level."))
    value <- if (id == "ordered") ordered(label, levels = levels(metadata$prototype)) else factor(label, levels = levels(metadata$prototype))
  }
  if (id == "posixct") value <- structure(as.numeric(value), class = class(metadata$prototype), tzone = attr(metadata$prototype, "tzone"))
  list(value = value, error = NULL)
}

table_assign_cell <- function(column, row, value, metadata) {
  cast <- table_cast_cell(value, metadata)
  if (!is.null(cast$error)) stop(cast$error, call. = FALSE)
  updated <- if (requireNamespace("vctrs", quietly = TRUE)) {
    tryCatch(vctrs::vec_assign(column, row, cast$value), error = function(e) {
      stop("Cannot assign this value without changing the column type: ", conditionMessage(e), call. = FALSE)
    })
  } else {
    candidate <- column
    candidate[row] <- cast$value
    candidate
  }
  if (!identical(typeof(updated), metadata$typeof) || !identical(class(updated), metadata$class) ||
      !identical(attributes(updated), attributes(column))) {
    stop("The edit would change the column type or attributes; the value was not applied.", call. = FALSE)
  }
  updated
}

table_replace_column <- function(data, column, value) {
  if (!inherits(data, "sf")) {
    data[[column]] <- value
    return(data)
  }

  expected_attributes <- attributes(data)
  geometry_name <- attr(data, "sf_column", exact = TRUE)
  geometry <- if (is.character(geometry_name) && length(geometry_name) == 1L &&
                  geometry_name %in% names(data)) data[[geometry_name]] else NULL
  candidate <- unclass(data)
  candidate[[column]] <- value
  attributes(candidate) <- expected_attributes
  if (!identical(attributes(candidate), expected_attributes) ||
      !identical(class(candidate), class(data)) ||
      !identical(names(candidate), names(data)) ||
      nrow(candidate) != nrow(data) ||
      !identical(attr(candidate, "sf_column", exact = TRUE), geometry_name) ||
      (!is.null(geometry) && !identical(candidate[[geometry_name]], geometry))) {
    stop("The edit would change sf metadata or geometry; the value was not applied.", call. = FALSE)
  }
  candidate
}
