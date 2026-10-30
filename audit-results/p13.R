suppressMessages(pkgload::load_all(".", quiet = TRUE))
for (txt in c("你好世界你好世界", "abcdefgh")) {
 a <- app(vertical(horizontal(label(txt, id = "l2"), button("OK", id = "b1"), input("你好世界", id = "i1"), id = "h")))
 p <- test_app(a, 40, 6)
 for (id in c("#b1", "#i1", "#b1", "#l2")) {
   w <- a$query_one(id); w$visible <- !w$visible; p$step()
   inc <- p$screen_text(); full <- compose_frame(a$screen, 40L, 6L)$to_text()
   cat(deparse(txt), "toggle", id, ":", identical(inc, full), "\n")
   if (!identical(inc, full)) { print(inc[1:3]); print(full[1:3]) }
   w$visible <- !w$visible; p$step()
 }
}
