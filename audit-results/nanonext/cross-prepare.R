root <- normalizePath(".", winslash = "/")
linux <- "/mnt/c/programming_pj/r_textualize"
for (direction in c("wsl-to-windows", "windows-to-wsl")) {
  path <- file.path(root, "audit-results/nanonext", direction)
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
  publisher_linux <- direction == "wsl-to-windows"
  base <- if (publisher_linux) sub(root, linux, path, fixed = TRUE) else path
  libraries <- if (publisher_linux) paste0(linux, "/audit-results/nanonext/lib-wsl") else paste0(root, "/audit-results/nanonext/lib-windows")
  config <- list(mode = "publisher", libraries = libraries, root = NULL, timeout = 30,
    endpoint = "tcp://127.0.0.1:0", snapshot_endpoint = "tcp://127.0.0.1:0",
    target = 20L, interval = 0.01, slow = FALSE,
    stop = file.path(base, "STOP"), go = file.path(base, "GO"),
    ready = file.path(base, "ready.json"), report = file.path(base, "publisher.json"))
  jsonlite::write_json(config, file.path(path, "config.json"), auto_unbox = TRUE, null = "null")
}
