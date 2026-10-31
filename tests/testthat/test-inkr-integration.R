test_that("apps without an inkr stylesheet retain the termr style path", {
  widget <- button("Run", style = style(foreground = "cyan", padding = 1))
  x <- app(widget)

  expect_null(x$inkr_stylesheet)
  expect_equal(widget$computed_style()$foreground, "cyan")
  expect_equal(widget$computed_style()$padding, c(1L, 1L, 1L, 1L))
})

test_that("inkr stylesheet integration is optional at use time", {
  skip_if(requireNamespace("inkr", quietly = TRUE))
  x <- app(button("Run"))
  expect_null(x$inkr_stylesheet)
  expect_silent(x$screen$children[[1]]$computed_style())
  expect_error(x$set_inkr_stylesheet("Button { color: red; }"), "optional package 'inkr'")
})

test_that("inkr declarations form a cascade layer above RTCSS and below inline style", {
  skip_if_not_installed("inkr")
  compiled <- inkr::ink_compile(inkr::ink_parse("Button { color: green; padding: 1 2; }"))
  plain <- button("Run")
  x <- app(plain, stylesheet = stylesheet("Button { color: blue; }"), inkr_stylesheet = compiled)

  expect_equal(plain$computed_style()$foreground, "green")
  expect_equal(plain$computed_style()$padding, c(1L, 2L, 1L, 2L))
  expect_s3_class(x$inkr_stylesheet, "ink_compiled_stylesheet")

  inline <- button("Inline", style = style(foreground = "yellow"))
  x <- app(inline, inkr_stylesheet = compiled)
  expect_equal(inline$computed_style()$foreground, "yellow")
})

test_that("inkr's typed built-in properties map into termr's style values", {
  skip_if_not_installed("inkr")
  compiled <- inkr::ink_compile(inkr::ink_parse(paste(
    "Button { color: #123; background: transparent; text-style: italic strike;",
    "padding: 1 2 3 4; margin: 2; border: heavy red; width: 20; height: auto; }"
  )))
  widget <- button("Run")
  x <- app(widget, inkr_stylesheet = compiled)
  st <- widget$computed_style()

  expect_equal(st$foreground, "#112233")
  expect_null(st$background)
  expect_equal(st$padding, c(1L, 2L, 3L, 4L))
  expect_equal(st$margin, rep(2L, 4L))
  expect_equal(st$border, "heavy")
  expect_equal(st$border_color, "red")
  expect_equal(st$width$type, "fixed")
  expect_equal(st$width$value, 20L)
  expect_equal(st$height$type, "auto")
  expect_equal(st$attrs, 68L)
})

test_that("disabled is passed as a live inkr pseudo state", {
  skip_if_not_installed("inkr")
  compiled <- inkr::ink_compile(inkr::ink_parse("Button:disabled { color: bright-blue; }"))
  widget <- button("Unavailable", disabled = TRUE)
  x <- app(widget, inkr_stylesheet = compiled)

  expect_equal(widget$computed_style()$foreground, "bright_blue")
})

test_that("inkr registry defaults do not replace termr widget defaults", {
  skip_if_not_installed("inkr")
  compiled <- inkr::ink_compile(inkr::ink_parse(""))
  widget <- button("Run", style = style(foreground = "magenta", padding = 3))
  x <- app(widget, inkr_stylesheet = compiled)

  expect_equal(widget$computed_style()$foreground, "magenta")
  expect_equal(widget$computed_style()$padding, c(3L, 3L, 3L, 3L))
})

test_that("inkr inheritance and nested selectors follow the live widget tree", {
  skip_if_not_installed("inkr")
  compiled <- inkr::ink_compile(inkr::ink_parse(
    ".danger { color: red; } .danger > Button { border: round yellow; }"
  ))
  child <- button("Delete")
  parent <- vertical(child, classes = "danger")
  x <- app(parent, inkr_stylesheet = compiled)

  expect_equal(child$computed_style()$foreground, "red")
  expect_equal(child$computed_style()$border, "round")
  expect_equal(child$computed_style()$border_color, "yellow")

  parent$remove_class("danger")
  expect_false(identical(child$computed_style()$foreground, "red"))
  parent$add_class("danger")
  expect_equal(child$computed_style()$foreground, "red")

  other <- vertical()
  x$screen$mount(other)
  other$mount(child)
  expect_false(identical(child$computed_style()$foreground, "red"))
})

test_that("direct id and class assignment invalidates selector styles", {
  skip_if_not_installed("inkr")
  compiled <- inkr::ink_compile(inkr::ink_parse(
    "Button.active { color: green; } #renamed { color: blue; }"
  ))
  widget <- button("Change", id = "before")
  other <- button("Other", id = "taken")
  x <- app(vertical(widget, other), inkr_stylesheet = compiled)

  expect_false(identical(widget$computed_style()$foreground, "green"))
  widget$classes <- "active"
  expect_equal(widget$computed_style()$foreground, "green")
  widget$id <- "renamed"
  expect_equal(widget$computed_style()$foreground, "blue")
  expect_error(widget$id <- "taken", "Duplicate widget id")
})

test_that("inkr pseudo states refresh and are explainable", {
  skip_if_not_installed("inkr")
  compiled <- inkr::ink_compile(inkr::ink_parse(
    "Button { color: white; } Button:focus { color: yellow; text-style: bold; }"
  ))
  widget <- button("Run")
  x <- app(widget, inkr_stylesheet = compiled)

  expect_equal(widget$computed_style()$foreground, "white")
  x$set_focus(widget)
  focused <- widget$computed_style()
  expect_equal(focused$foreground, "yellow")
  expect_true(bitwAnd(focused$attrs, 1L) > 0L)
  explanation <- x$explain_inkr_style(widget, "color")
  expect_s3_class(explanation, "ink_style_explanation")
  expect_identical(explanation$value, inkr::ink_compute(compiled, inkr::ink_element("Button", states = "focus"))$values$color)
  inspection <- inspect_widget(x, "Button")
  expect_true("color" %in% names(inspection$inkr))
  expect_match(paste(capture.output(print(inspection)), collapse = "\n"), "inkr rules:")
})

test_that("inkr sheets can switch themes without stale widget styles", {
  skip_if_not_installed("inkr")
  light <- inkr::ink_compile(inkr::ink_parse("Button { color: blue; }"))
  dark <- inkr::ink_compile(inkr::ink_parse("Button { color: white; }"))
  widget <- button("Theme")
  x <- app(widget, inkr_stylesheet = light)

  expect_equal(widget$computed_style()$foreground, "blue")
  x$theme <- "dark"
  x$set_inkr_stylesheet(dark)
  expect_equal(widget$computed_style()$foreground, "white")
  expect_identical(x$inkr_stylesheet, dark)
})

test_that("inkr applies through native chart and typed DataTable widgets", {
  skip_if_not_installed("inkr")
  chart <- line_chart(1:3, c(2, 3, 4), classes = "series", interactive = FALSE)
  table <- data_table(data.frame(value = c(2L, 3L)), show_types = TRUE, row_names = FALSE)
  compiled <- inkr::ink_compile(inkr::ink_parse(
    "ChartWidget.series { color: cyan; } DataTable { padding: 1; border: round yellow; }"
  ))
  x <- app(vertical(chart, table), inkr_stylesheet = compiled)

  expect_equal(chart$computed_style()$foreground, "cyan")
  expect_equal(table$computed_style()$padding, rep(1L, 4L))
  expect_equal(table$computed_style()$border, "round")
})

test_that("stylesheet replacement is atomic and supports files and ASTs", {
  skip_if_not_installed("inkr")
  old <- inkr::ink_compile(inkr::ink_parse("Button { color: red; }"))
  widget <- button("Run")
  x <- app(widget, inkr_stylesheet = old)

  expect_error(x$set_inkr_stylesheet("Button { color: not-a-color; }"))
  expect_identical(x$inkr_stylesheet, old)
  expect_error(x$set_inkr_stylesheet(structure(list(), class = "ink_compiled_stylesheet")))
  expect_identical(x$inkr_stylesheet, old)
  expect_equal(widget$computed_style()$foreground, "red")

  ast <- inkr::ink_parse("Button { color: blue; }")
  x$set_inkr_stylesheet(ast)
  expect_equal(widget$computed_style()$foreground, "blue")

  path <- tempfile(fileext = ".inkr")
  on.exit(unlink(path), add = TRUE)
  writeLines("Button { color: cyan; }", path, useBytes = TRUE)
  x$set_inkr_stylesheet(path)
  expect_equal(widget$computed_style()$foreground, "cyan")

  x$set_inkr_stylesheet("/* Source text may contain https:// references. */ Button { color: magenta; }")
  expect_equal(widget$computed_style()$foreground, "magenta")
  expect_error(x$set_inkr_stylesheet("https://example.test/theme.inkr"), "Remote inkr stylesheets")
  expect_error(x$set_inkr_stylesheet("missing.inkr"), "does not exist")
  expect_equal(widget$computed_style()$foreground, "magenta")

  x$clear_inkr_stylesheet()
  expect_null(x$inkr_stylesheet)
})

test_that("transparent inkr backgrounds preserve the underlying paint", {
  skip_if_not_installed("inkr")
  compiled <- inkr::ink_compile(inkr::ink_parse("Button { background: transparent; }"))
  widget <- button("Run")
  x <- app(widget, stylesheet = stylesheet("Button { background: red; }"), inkr_stylesheet = compiled)

  expect_null(widget$computed_style()$background)
})

test_that("unsupported alpha colors fail with a focused message", {
  skip_if_not_installed("inkr")
  compiled <- inkr::ink_compile(inkr::ink_parse("Button { color: #11223380; }"))
  widget <- button("Run")
  x <- app(widget, inkr_stylesheet = compiled)

  expect_error(widget$computed_style(), "cannot represent")
})
