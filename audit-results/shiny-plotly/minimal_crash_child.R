host <- if (.Platform$OS.type == "windows") "windows" else "wsl"
.libPaths(c(file.path("audit-results/shiny-plotly", paste0("lib-", host)),
  file.path("audit-results/nanonext", paste0("lib-", host)), .libPaths()))
mode <- commandArgs(trailingOnly = TRUE)[[1L]]
if (mode == "pkgload") library(pkgload)
if (mode == "testthat") library(testthat)
if (mode == "rlang") library(rlang)
if (mode == "cli") library(cli)
if (mode == "shiny") library(shiny)
if (mode == "shiny-mock") {s <- shiny::MockShinySession$new(); s$close()}
if (mode == "testserver") shiny::testServer(function(input, output, session) {}, {session$flushReact(); session$close()})
if (mode == "test-that") testthat::test_that("control", testthat::expect_true(TRUE))
cat("BODY COMPLETED", mode, "\n")
cat("SystemRoot", Sys.getenv("SystemRoot"), "PATH bytes", nchar(Sys.getenv("PATH")), "\n")
cat("LOADED", loadedNamespaces(), "\n")
