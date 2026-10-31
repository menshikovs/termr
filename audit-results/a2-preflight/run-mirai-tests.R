Sys.setenv(NOT_CRAN = "true")
testthat::test_local(".", filter = "mirai", reporter = "summary")
