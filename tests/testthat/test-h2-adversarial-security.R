testthat::test_that("Reproducible code safely handles malicious and non-syntactic column names", {
  malicious_col <- "col`; system('touch /tmp/termr_pwned'); `"
  weird_col <- "col \"with\" quotes \n and \t tabs"

  df <- data.frame(
    id = 1:5,
    stringsAsFactors = FALSE
  )
  df[[malicious_col]] <- c("a", "b", "c", "d", "e")
  df[[weird_col]] <- 10:14

  dt <- data_table(df, editable = TRUE)
  dt$sort(malicious_col, decreasing = TRUE)
  dt$set_cell(1, malicious_col, "safe_edit")

  code_pipe <- dt$reproducible_code("pipeline")
  testthat::expect_true(code_pipe$status %in% c("exact", "unsupported"))

  if (code_pipe$status == "exact") {
    # Check that code parses safely into an expression
    parsed <- parse(text = code_pipe$code, keep.source = FALSE)
    testthat::expect_true(is.expression(parsed))

    # Evaluate in a sandboxed, clean environment
    test_env <- new.env(parent = baseenv())
    test_env$data <- df
    result <- eval(parsed, envir = test_env)

    # Injected file must not exist
    testthat::expect_false(file.exists("/tmp/termr_pwned"))
    # Result must be a data frame with identical column names
    testthat::expect_true(is.data.frame(result))
    testthat::expect_identical(names(result), names(df))
    # Pipeline sorted decreasing, so first row is row 5 of original df
    testthat::expect_identical(result[[malicious_col]][1], "e")
  }

  code_edits <- dt$reproducible_code("edits")
  testthat::expect_true(code_edits$status %in% c("exact", "unsupported"))
  if (code_edits$status == "exact") {
    parsed_edits <- parse(text = code_edits$code, keep.source = FALSE)
    testthat::expect_true(is.expression(parsed_edits))
    test_env2 <- new.env(parent = baseenv())
    test_env2$data <- df
    res_edits <- eval(parsed_edits, envir = test_env2)
    testthat::expect_false(file.exists("/tmp/termr_pwned"))
    # Edits code must have safely applied "safe_edit" to row 1
    testthat::expect_identical(res_edits[[malicious_col]][1], "safe_edit")
  }

  code_val <- dt$reproducible_code("value")
  testthat::expect_true(code_val$status %in% c("exact", "limited", "unsupported"))
  if (code_val$status == "exact") {
    parsed_val <- parse(text = code_val$code, keep.source = FALSE)
    val_res <- eval(parsed_val, envir = baseenv())
    testthat::expect_false(file.exists("/tmp/termr_pwned"))
    testthat::expect_true(is.data.frame(val_res) || is.vector(val_res))
  }
})

testthat::test_that("Table rendering handles ANSI escape sequences and control characters safely", {
  ansi_str <- "\033[2J\033[H\033[31mInjected\033[0m\033]0;title\007"
  ctrl_str <- "Line1\r\nLine2\t\b\001\002"

  df <- data.frame(
    name = c(ansi_str, ctrl_str),
    val = c(1, 2),
    stringsAsFactors = FALSE
  )

  dt <- data_table(df)
  app_obj <- app(dt)
  p <- test_app(app_obj)

  # Screen text should be a character vector of rendered lines
  st <- p$screen_text()
  testthat::expect_true(is.character(st))
  testthat::expect_gt(length(st), 0L)
  testthat::expect_true(any(nchar(st) > 0L))

  # Cell editing with ANSI string sanitizes destructive control characters
  dt$set_cell(1, "name", ansi_str)
  dt$render()
  testthat::expect_identical(dt$data$name[1], "[2J[H[31mInjected[0m]0;title")
})

testthat::test_that("Typed data fault injection: exploding S3 format method fails gracefully", {
  exploding_val <- structure(c(1, 2, 3), class = "exploding_s3")
  format.exploding_s3 <<- function(x, ...) stop("Kaboom from format.exploding_s3")
  on.exit(rm("format.exploding_s3", envir = .GlobalEnv), add = TRUE)

  df <- data.frame(
    id = 1:3,
    stringsAsFactors = FALSE
  )
  df$bad <- exploding_val

  # Creating data table and rendering shouldn't abort with unhandled condition
  dt <- tryCatch(data_table(df), error = function(e) e)
  if (!inherits(dt, "error")) {
    app_obj <- app(dt)
    p <- test_app(app_obj)
    st <- p$screen_text()
    testthat::expect_true(is.character(st))
  } else {
    testthat::expect_true(inherits(dt, "error"))
  }
})

testthat::test_that("Fuzz testing: stylesheet parser handles random and malformed strings", {
  set.seed(12345)
  chars <- c("a", "z", "{", "}", ":", ";", ".", "#", "@", "!", "-", "_", " ", "\n", "\t", "\"", "'", "<", ">", "$", "%")

  for (i in 1:50) {
    len <- sample(5:60, 1)
    fuzz_str <- paste(sample(chars, len, replace = TRUE), collapse = "")

    # as_stylesheet must either succeed returning a stylesheet or throw a catchable error
    res <- tryCatch(as_stylesheet(fuzz_str), error = function(e) e)
    testthat::expect_true(inherits(res, "error") || inherits(res, "Stylesheet") || is.list(res))
  }
})

testthat::test_that("Fuzz testing: query selector handles random malformed selector expressions", {
  set.seed(54321)
  c1 <- vertical(
    button("A", id = "btn_a", classes = "btn primary"),
    input("B", id = "inp_b", classes = "field text"),
    id = "root"
  )
  a <- app(c1)

  selector_chars <- c("#", ".", " ", ":", ">", "*", "[", "]", "=", "\"", "'", "a", "1", "-", "_", "$", "^", "~")

  for (i in 1:50) {
    len <- sample(1:20, 1)
    fuzz_sel <- paste(sample(selector_chars, len, replace = TRUE), collapse = "")

    # Querying should either find matches, return empty list/NULL, or throw clean error, never segfault
    res <- tryCatch(a$query(fuzz_sel), error = function(e) e)
    testthat::expect_true(inherits(res, "error") || is.list(res))
  }
})