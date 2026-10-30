test_that("text_cells splits ASCII into single-width cells", {
  cells <- text_cells("abc")
  expect_identical(cells$chars, c("a", "b", "c"))
  expect_identical(cells$widths, c(1L, 1L, 1L))
})

test_that("text_cells reports wide characters", {
  cells <- text_cells("a\u4e2db")
  expect_identical(cells$chars, c("a", "\u4e2d", "b"))
  expect_identical(cells$widths, c(1L, 2L, 1L))
  expect_identical(str_width("a\u4e2db"), 4L)
})

test_that("combining characters stay with their base character", {
  cells <- text_cells("e\u0301x")
  expect_identical(cells$chars, c("e\u0301", "x"))
  expect_identical(cells$widths, c(1L, 1L))
})

test_that("control characters are removed so text cannot inject escapes", {
  expect_identical(sanitize_text("a\033[31mb\tc"), "a[31mb c")
  expect_identical(text_cells("\033")$chars, character())
})

test_that("str_truncate and str_align respect display width", {
  expect_identical(str_truncate("hello", 3), "hel")
  expect_identical(str_truncate("\u4e2d\u6587", 3), "\u4e2d")
  expect_identical(str_align("ab", 6, "center"), "  ab  ")
  expect_identical(str_align("ab", 5, "right"), "   ab")
  expect_identical(str_align("abcdef", 3), "abc")
})

test_that("C1 control characters never reach the framebuffer", {
  csi <- intToUtf8(0x9b)
  expect_identical(sanitize_text(paste0("a", csi, "2Jb")), "a2Jb")
  expect_identical(cell(paste0("\033", csi))$char, " ")
  buf <- render_widget(label(paste0("x", csi, "y")), 5, 1)
  expect_false(any(grepl(csi, buf$chars, fixed = TRUE)))
  expect_identical(sanitize_text("caf\u00e9 \u00a0ok"), "caf\u00e9 \u00a0ok")
})

test_that("sanitize_text matches the reference definition on every kind of input", {
  reference <- function(x) {
    x <- enc2utf8(as.character(x))
    x <- gsub("\t", " ", x, fixed = TRUE)
    gsub("[\\x{01}-\\x{1f}\\x{7f}-\\x{9f}]", "", x, perl = TRUE)
  }
  fixed <- c("", " ", "plain ascii text", "tab\there", "a\nb", "ctl\001x\037y\177z", "\u0080\u009f kept?", "\u00a0nbsp",
             "\u043f\u0440\u0438\u0432\u0435\u0442", "\u4f60\u597d", "\U0001F600", "e\u0301", "\u200d",
             "\033[31mred\033[0m", "~", "\x7e}", NA_character_)
  expect_identical(sanitize_text(fixed), reference(fixed))
  for (s in fixed) expect_identical(sanitize_text(s), reference(s))
  set.seed(42)
  pool <- intToUtf8(c(1:126, 127:160, 0x4f60, 0x1F600, 0x301, 0x200d, 0x2028), multiple = TRUE)
  random <- vapply(1:500, function(i) paste(sample(pool, sample(0:12, 1), TRUE), collapse = ""), "")
  expect_identical(sanitize_text(random), reference(random))
  expect_identical(sanitize_text(factor(c("a\tb", "c"))), reference(factor(c("a\tb", "c"))))
  expect_identical(sanitize_text(12.5), reference(12.5))
  expect_identical(sanitize_text(character()), reference(character()))
})
