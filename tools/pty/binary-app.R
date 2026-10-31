root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
suppressPackageStartupMessages(pkgload::load_all(root, attach = TRUE, quiet = TRUE))

payload <- as.raw(c(0x1B, 0x00, 0xFF, 0xC3))
data <- data.frame("payload_µ" = payload, check.names = FALSE)
table <- data_table(data, cursor = "none", show_types = TRUE)
run(app(table, bind("q", "quit")))
