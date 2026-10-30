test_that("style() stores only the properties that were set", {
  st <- style(width = 20, padding = c(1, 2), bold = TRUE, foreground = "Red")
  expect_s3_class(st, "termr_style")
  expect_setequal(names(st$props), c("width", "padding", "bold", "foreground"))
  expect_identical(st$props$width, size_spec("fixed", 20L))
  expect_identical(st$props$padding, c(1L, 2L, 1L, 2L))
  expect_identical(st$props$foreground, "red")
})

test_that("sizes are parsed from numbers and strings", {
  expect_identical(parse_size(3), size_spec("fixed", 3L))
  expect_identical(parse_size("auto"), size_spec("auto"))
  expect_identical(parse_size("2fr"), size_spec("fr", 2))
  expect_identical(parse_size("50%"), size_spec("percent", 0.5))
  expect_error(style(width = "wide"), "Invalid `width`")
})

test_that("style() validates its arguments", {
  expect_error(style(border = "fancy"), "`border` must be one of")
  expect_error(style(bold = "yes"), "`bold` must be TRUE or FALSE")
  expect_error(style(min_width = -1), "non-negative")
  expect_error(style(background = "nope"), "Unknown colour")
})

test_that("merge_styles layers properties and state styles", {
  a <- style(width = 10, bold = TRUE, focus = style(background = "blue"))
  b <- style(width = 20, focus = style(foreground = "white"))
  m <- merge_styles(a, b)
  expect_identical(m$props$width, size_spec("fixed", 20L))
  expect_true(m$props$bold)
  expect_identical(m$states$focus$props$background, "blue")
  expect_identical(m$states$focus$props$foreground, "white")
})

test_that("resolve_style applies active states and inherits foreground", {
  st <- style(foreground = "red", focus = style(foreground = "green", underline = TRUE))
  parent <- resolve_style(style(foreground = "yellow"))
  plain <- resolve_style(st)
  focused <- resolve_style(st, "focus")
  expect_identical(plain$foreground, "red")
  expect_identical(focused$foreground, "green")
  expect_true(attrs_decode(focused$attrs)[["underline"]])
  child <- resolve_style(style(), parent = parent)
  expect_identical(child$foreground, "yellow")
  expect_null(child$background)
})

test_that("span() builds styled text that can be combined", {
  txt <- c(span("a"), "b\nc", span("d", style(bold = TRUE)))
  expect_identical(as.character(txt), "ab\ncd")
  lines <- text_lines(txt)
  expect_length(lines, 2)
  expect_identical(vapply(lines[[2]], `[[`, "", "text"), c("c", "d"))
  expect_identical(line_width(lines[[1]]), 2L)
})

test_that("absurdly large cell counts are clamped instead of failing in layout", {
  huge <- list(Inf, 1e10, 2^31, .Machine$integer.max)
  props <- c("width", "height", "min_width", "max_width", "min_height", "max_height", "margin", "padding")
  for (prop in props) {
    for (v in huge) {
      a <- app(vertical(label("hello", style = do.call(style, stats::setNames(list(v), prop))), label("x")))
      pilot <- test_app(a, 20, 4)
      expect_no_error(pilot$step())
      expect_identical(pilot$screen_text(), compose_frame(a$screen, 20L, 4L)$to_text())
      pilot$stop()
    }
  }
  a <- app(horizontal(label("a", style = style(width = .Machine$integer.max)),
                      label("b", style = style(width = .Machine$integer.max))))
  expect_no_error(test_app(a, 10, 2)$stop())
})

test_that("unusable grid track counts are rejected up front and gaps are clamped", {
  for (v in list(Inf, 1e10, .Machine$integer.max)) {
    expect_error(style(grid_columns = v), "grid_columns")
    expect_error(style(grid_rows = v), "grid_rows")
  }
  expect_no_error(style(grid_gap = Inf))
  expect_error(style(grid_gap = NA), "grid_gap")
})

test_that("clamping keeps the original rounding of cell values", {
  expect_identical(style(margin = 1.9)$props$margin, rep(1L, 4L))
  expect_identical(style(min_width = 2.7)$props$min_width, 2L)
  expect_identical(parse_size(2.5)$value, 2L)
  expect_identical(parse_size(3.5)$value, 4L)
  expect_identical(parse_size("12")$value, 12L)
})

test_that("parse_size results are stable under repeated and cached parsing", {
  reference <- function(s) {
    s <- tolower(trimws(s))
    if (s == "auto") return(list(type = "auto", value = NA_real_))
    if (grepl("^[0-9]*[.]?[0-9]+fr$", s)) return(list(type = "fr", value = as.numeric(sub("fr$", "", s))))
    if (grepl("^[0-9]*[.]?[0-9]+%$", s)) return(list(type = "percent", value = as.numeric(sub("%$", "", s)) / 100))
    list(type = "fixed", value = as.integer(s))
  }
  inputs <- c("auto", "AUTO", " auto ", "1fr", "2.5fr", ".5fr", "3FR", "50%", "12.5%", "100%", "0%", "7", "007", "12")
  for (round_ in 1:3) for (s in inputs) {
    got <- parse_size(s)
    want <- reference(s)
    expect_identical(unclass(got)$type, want$type)
    expect_equal(unclass(got)$value, want$value)
  }
  # a returned spec can be modified by the caller without affecting later parses
  first <- parse_size("1fr")
  first$value <- 99
  expect_equal(parse_size("1fr")$value, 1)
  for (bad in c("", NA_character_, "fr", "-1fr", "1e9fr", "NaN%", "1 fr", "abc")) {
    expect_error(parse_size(bad), "Invalid")
    expect_error(parse_size(bad), "Invalid")
  }
  for (i in 1:2000) parse_size(paste0(i, "fr"))
  expect_equal(parse_size("1999fr")$value, 1999)
})
