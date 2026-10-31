phase <- commandArgs(TRUE)[[1L]]
pkgload::load_all('.', quiet=TRUE)
q <- termr:::EventQueue$new()
q$push(0L)
g <- gc()
rows <- list()
for (batch in 1:10) {
  for (i in 1:5000) {q$push(i); q$pop()}
  used <- gc()
  keys <- ls(q$.__enclos_env__$private$items, all.names=TRUE)
  rows[[batch]] <- data.frame(operations=batch*5000L, pending=q$size(), max_live_key=max(as.numeric(keys)),
    ncells_delta=used[1,'used']-g[1,'used'], vcells_delta=used[2,'used']-g[2,'used'])
}
write.csv(do.call(rbind,rows), paste0('audit-results/hardening/h3-performance/queue-lifetime-',phase,'.csv'),row.names=FALSE)
