Sys.setenv(LC_ALL = "C.UTF-8", LC_CTYPE = "C.UTF-8", TZ = "UTC")
setwd("/mnt/c/programming_pj/r_textualize")
testthat::test_local(".", filter = "datatable-reproducible-code", reporter = "summary")
