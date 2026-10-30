suppressMessages(pkgload::load_all(Sys.getenv("PKG", "."), quiet = TRUE))
a <- app(vertical(horizontal(label("你好世界你好世界", id = "l"), button("OK", id = "b"))))
p <- test_app(a, 30, 5)
full0 <- compose_frame(a$screen, 30L, 5L)$to_text()
cat("initial inc == full:", identical(p$screen_text(), full0), "\n")
a$query_one("#b")$focus(); p$step()
inc <- p$screen_text(); full <- compose_frame(a$screen, 30L, 5L)$to_text()
cat("after focus inc == full:", identical(inc, full), "\n"); if (!identical(inc, full)) { print(inc[1:3]); print(full[1:3]) }
