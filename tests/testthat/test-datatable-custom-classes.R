new_termr_ext_integer <- function(x = integer(), tag = "id") {
  structure(as.integer(x), tag = tag, class = "termr_ext_integer")
}

format.termr_ext_integer <- function(x, ...) paste0("#", unclass(x))

xtfrm.termr_ext_integer <- function(x) as.double(unclass(x))

`[.termr_ext_integer` <- function(x, i, ...) {
  structure(unclass(x)[i], tag = attr(x, "tag", exact = TRUE), class = class(x))
}

new_termr_ext_character <- function(x = character(), origin = "source") {
  structure(as.character(x), origin = origin, class = "termr_ext_character")
}

format.termr_ext_character <- function(x, ...) paste0("text:", unclass(x))

new_termr_ext_quantity <- function(x = double(), unit = "u") {
  vctrs::new_vctr(as.double(x), unit = unit, class = "termr_ext_quantity")
}

termr_ext_pillar_rows <- integer()

format.termr_ext_quantity <- function(x, ...) {
  paste0(format(vctrs::vec_data(x), trim = TRUE), " ", attr(x, "unit", exact = TRUE))
}

vec_ptype_abbr.termr_ext_quantity <- function(x, ...) "qty"

pillar_shaft.termr_ext_quantity <- function(x, ...) {
  termr_ext_pillar_rows <<- c(termr_ext_pillar_rows, length(x))
  pillar::new_pillar_shaft_simple(format(x), align = "right")
}

vec_cast.termr_ext_quantity.character <- function(x, to, ...) {
  if (!length(x)) return(new_termr_ext_quantity(double(), attr(to, "unit", exact = TRUE)))
  if (anyNA(x)) stop("missing text must be explicit", call. = FALSE)
  if (identical(x, "NA")) {
    return(new_termr_ext_quantity(NA_real_, attr(to, "unit", exact = TRUE)))
  }
  pattern <- "^[+-]?(?:[0-9]+(?:\\.[0-9]*)?|\\.[0-9]+)(?:[eE][+-]?[0-9]+)?$"
  if (any(!grepl(pattern, x, perl = TRUE))) stop("expected a decimal quantity", call. = FALSE)
  value <- suppressWarnings(as.double(x))
  if (any(!is.finite(value))) stop("quantity is outside the finite range", call. = FALSE)
  new_termr_ext_quantity(value, attr(to, "unit", exact = TRUE))
}

new_termr_ext_guarded <- function(x = double()) {
  vctrs::new_vctr(as.double(x), rule = "finite", class = "termr_ext_guarded")
}

vec_cast.termr_ext_guarded.character <- function(x, to, ...) {
  if (!length(x)) return(new_termr_ext_guarded())
  if (any(!grepl("^-?[0-9]+$", x))) stop("expected an integer", call. = FALSE)
  value <- as.double(x)
  if (any(!is.finite(value) | value < 0)) stop("values must be non-negative", call. = FALSE)
  new_termr_ext_guarded(value)
}

new_termr_ext_restore <- function(x = double(), restored = "stable") {
  vctrs::new_vctr(as.double(x), restored = restored, class = "termr_ext_restore")
}

vec_cast.termr_ext_restore.character <- function(x, to, ...) {
  if (!length(x)) return(new_termr_ext_restore())
  value <- suppressWarnings(as.double(x))
  if (anyNA(value) || any(!is.finite(value))) stop("expected a finite value", call. = FALSE)
  new_termr_ext_restore(value, attr(to, "restored", exact = TRUE))
}

vec_restore.termr_ext_restore <- function(x, to, ..., i = NULL) {
  new_termr_ext_restore(x, restored = "custom restore changed metadata")
}

new_termr_ext_broken <- function(x = double()) {
  structure(as.double(x), class = "termr_ext_broken")
}

format.termr_ext_broken <- function(x, ...) stop("deliberate formatter failure", call. = FALSE)

pillar_shaft.termr_ext_broken <- function(x, ...) {
  stop("deliberate pillar failure", call. = FALSE)
}

new_termr_ext_malformed <- function(x = double()) {
  structure(as.double(x), class = "termr_ext_malformed")
}

pillar_shaft.termr_ext_malformed <- function(x, ...) {
  structure(character(), class = "pillar_shaft")
}

new_termr_ext_unsafe <- function(x = 1L) structure(as.integer(x), class = "termr_ext_unsafe")

format.termr_ext_unsafe <- function(x, ...) {
  rep(paste0("\033[2J", strrep("long", 100L)), length(x))
}

with_termr_ext_methods <- function(code) {
  registrations <- list(
    list(package = "base", generic = "format", class = "termr_ext_integer",
         method = format.termr_ext_integer),
    list(package = "base", generic = "[", class = "termr_ext_integer",
         method = `[.termr_ext_integer`),
    list(package = "base", generic = "xtfrm", class = "termr_ext_integer",
         method = xtfrm.termr_ext_integer),
    list(package = "base", generic = "format", class = "termr_ext_character",
         method = format.termr_ext_character),
    list(package = "base", generic = "format", class = "termr_ext_quantity",
         method = format.termr_ext_quantity),
    list(package = "vctrs", generic = "vec_ptype_abbr", class = "termr_ext_quantity",
         method = vec_ptype_abbr.termr_ext_quantity),
    list(package = "pillar", generic = "pillar_shaft", class = "termr_ext_quantity",
         method = pillar_shaft.termr_ext_quantity),
    list(package = "vctrs", generic = "vec_cast", class = "termr_ext_quantity.character",
         method = vec_cast.termr_ext_quantity.character),
    list(package = "vctrs", generic = "vec_cast", class = "termr_ext_guarded.character",
         method = vec_cast.termr_ext_guarded.character),
    list(package = "vctrs", generic = "vec_cast", class = "termr_ext_restore.character",
         method = vec_cast.termr_ext_restore.character),
    list(package = "vctrs", generic = "vec_restore", class = "termr_ext_restore",
         method = vec_restore.termr_ext_restore),
    list(package = "base", generic = "format", class = "termr_ext_broken",
         method = format.termr_ext_broken),
    list(package = "pillar", generic = "pillar_shaft", class = "termr_ext_broken",
         method = pillar_shaft.termr_ext_broken),
    list(package = "pillar", generic = "pillar_shaft", class = "termr_ext_malformed",
         method = pillar_shaft.termr_ext_malformed),
    list(package = "base", generic = "format", class = "termr_ext_unsafe",
         method = format.termr_ext_unsafe)
  )
  active <- list()
  on.exit({
    for (registration in rev(active)) {
      try(removeS3method(registration$generic, registration$class,
                         envir = asNamespace(registration$package)), silent = TRUE)
    }
  }, add = TRUE)
  for (registration in registrations) {
    if (!requireNamespace(registration$package, quietly = TRUE)) next
    namespace <- asNamespace(registration$package)
    try(removeS3method(registration$generic, registration$class, envir = namespace), silent = TRUE)
    registerS3method(registration$generic, registration$class, registration$method, envir = namespace)
    active[[length(active) + 1L]] <- registration
  }
  force(code)
}

test_that("custom S3 classes use safe standard formatting and retain class-chain metadata", {
  with_termr_ext_methods({
    ints <- new_termr_ext_integer(c(2L, 1L), tag = "ticket")
    chars <- new_termr_ext_character(c("α", "β"), origin = "import")
    custom_date <- structure(
      as.numeric(as.Date(c("2024-01-01", "2024-01-02"))),
      class = c("termr_ext_date", "Date")
    )

    expect_identical(table_type_handler(ints)$id, "extension")
    expect_identical(table_type_handler(chars)$id, "extension")
    expect_identical(table_type_handler(custom_date)$id, "extension")
    expect_identical(table_column_metadata(ints)$class, c("termr_ext_integer"))
    expect_identical(table_column_metadata(ints)$attributes$class, class(ints))
    expect_identical(table_column_metadata(ints)$attributes$tag, "ticket")
    expect_identical(trimws(table_format_values(ints)), c("#2", "#1"))
    expect_identical(trimws(table_format_values(chars)), c("text:α", "text:β"))
    expect_match(table_format_values(custom_date)[[2L]], "2024-01-02")
    expect_false(table_column_metadata(ints)$editable)
    expect_length(table_type_summary(ints), 1L)
    expect_true(nzchar(table_type_summary(ints)))
    expect_lte(str_width(table_type_summary(ints)), 24L)
  })
})

test_that("pillar and vctrs adapters format custom vctrs classes on bounded slices", {
  with_termr_ext_methods({
    old_rows <- termr_ext_pillar_rows
    on.exit(termr_ext_pillar_rows <<- old_rows, add = TRUE)
    skip_if_not_installed("vctrs")
    skip_if_not_installed("pillar")
    values <- new_termr_ext_quantity(seq_len(100000L), unit = "widgets")
    selected <- table_slice(values, c(1L, 50000L, 100000L))
    termr_ext_pillar_rows <<- integer()
    output <- table_format_values(selected, width = 12L)

    expect_identical(table_type_summary(values), "qty")
    expect_length(output, 3L)
    expect_true(all(str_width(output) <= 12L))
    expect_identical(termr_ext_pillar_rows, 3L)
    expect_match(table_format_values(selected)[[1L]], "widgets")
    expect_identical(attr(selected, "unit", exact = TRUE), "widgets")
    expect_true(table_column_metadata(values)$editable)

    termr_ext_pillar_rows <<- integer()
    table <- data_table(data.frame(value = values), cursor = "none")
    expect_true(length(termr_ext_pillar_rows) > 0L)
    expect_lte(max(termr_ext_pillar_rows), 1000L)
    termr_ext_pillar_rows <<- integer()
    render_widget(table, width = 40L, height = 10L)
    expect_true(length(termr_ext_pillar_rows) > 0L)
    expect_lte(max(termr_ext_pillar_rows), 1000L)
  })
})

test_that("vctrs text casts enable only invariant-preserving custom edits", {
  with_termr_ext_methods({
    skip_if_not_installed("vctrs")
    source <- data.frame(value = new_termr_ext_quantity(c(1, 2), unit = "m"))
    table <- data_table(source, editable = TRUE)
    before <- table$data

    table$set_cell(1L, "value", "3.5")
    expect_identical(class(table$data$value), class(source$value))
    expect_identical(attributes(table$data$value), attributes(source$value))
    expect_equal(vctrs::vec_data(table$data$value), c(3.5, 2))
    expect_identical(source, before)

    table$set_cell(2L, "value", "NA")
    expect_true(is.na(vctrs::vec_data(table$data$value)[[2L]]))
    expect_identical(attributes(table$data$value), attributes(source$value))
    expect_identical(table_format_values(table$data$value), c("3.5 m", "NA"))

    after <- table$data
    expect_error(table$set_cell(2L, "value", "bad"), "decimal quantity")
    expect_identical(table$data, after)

    guarded <- data_table(data.frame(value = new_termr_ext_guarded(c(1, 2))), editable = TRUE)
    expect_error(guarded$set_cell(1L, "value", "-4"), "non-negative")
    expect_identical(vctrs::vec_data(guarded$data$value), c(1, 2))
  })
})

test_that("custom vec_restore metadata changes reject assignment atomically", {
  with_termr_ext_methods({
    skip_if_not_installed("vctrs")
    source <- data.frame(value = new_termr_ext_restore(c(1, 2)))
    table <- data_table(source, editable = TRUE)
    before <- table$data

    expect_error(table$set_cell(1L, "value", "9"), "attributes|type")
    expect_identical(table$data, before)
    expect_identical(attr(table$data$value, "restored", exact = TRUE), "stable")
  })
})

test_that("custom formatter and pillar failures degrade to bounded safe text", {
  with_termr_ext_methods({
    skip_if_not_installed("pillar")
    broken <- new_termr_ext_broken(c(1, 2))
    result <- table_format_values(broken, width = 10L)

    expect_length(result, 2L)
    expect_true(all(nzchar(result)))
    expect_true(all(str_width(result) <= 10L))
    expect_false(any(grepl("deliberate", result, fixed = TRUE)))

    malformed <- table_format_values(new_termr_ext_malformed(1), width = 8L)
    expect_length(malformed, 1L)
    expect_lte(str_width(malformed), 8L)
    expect_false(grepl("\\033", malformed))

    unsafe <- table_format_values(new_termr_ext_unsafe(), width = 8L)
    expect_length(unsafe, 1L)
    expect_lte(str_width(unsafe), 8L)
    expect_false(grepl("\\033", unsafe))
  })
})

test_that("custom typed sorting and filtering preserve source rows and attributes", {
  with_termr_ext_methods({
    ints <- new_termr_ext_integer(c(3L, 1L, 2L), tag = "stable")
    source <- data.frame(id = c("c", "a", "b"), value = ints)
    original <- source
    table <- data_table(source)
    sorter <- data_table(source)

    sorter$sort("value")
    expect_identical(sorter$view, c(2L, 3L, 1L))

    table$sort("id")
    expect_identical(table$view, c(2L, 3L, 1L))
    expect_identical(table$data$value, original$value)
    expect_identical(attributes(table$data$value), attributes(original$value))
    table$filter_columns(list(value = table_filter("contains", "#2")))
    expect_identical(table$view, 3L)
    expect_identical(source, original)
  })
})

test_that("seeded custom vctrs editing remains scalar, typed and atomic", {
  with_termr_ext_methods({
    skip_if_not_installed("vctrs")
    set.seed(2606)
    values <- stats::runif(40L, min = 0, max = 100)
    source <- data.frame(value = new_termr_ext_quantity(values, unit = "pt"))
    original <- source
    table <- data_table(source, editable = TRUE)

    for (i in seq_len(30L)) {
      row <- sample.int(nrow(source), 1L)
      replacement <- sprintf("%.9f", stats::runif(1L, min = 0, max = 100))
      table$set_cell(row, "value", replacement)
      expect_identical(class(table$data$value), class(source$value))
      expect_identical(attributes(table$data$value), attributes(source$value))
      expect_length(vctrs::vec_data(table$data$value), nrow(source))
      expect_identical(source, original)
    }
    before <- table$data
    for (bad in c("", "NaN", "Inf", "12 kg", "2.0.0", "1e10000")) {
      expect_error(table$set_cell(1L, "value", bad))
      expect_identical(table$data, before)
    }
  })
})
