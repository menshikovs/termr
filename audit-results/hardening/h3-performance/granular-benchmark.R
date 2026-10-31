# Invoke as phase granular. No package code is modified.
source('audit-results/hardening/h3-performance/benchmark-frozen.R')
for (enabled in c(FALSE,TRUE)) for (op in c('layout','paint')) {
  measure(paste0(op,'-only-',if(enabled) 'inkr' else 'plain'),1000L,function() {
    x <- make_tree(1000L, ids=TRUE, ink=enabled)
    if (op=='paint') internal('layout_tree')(x$a$screen, internal('rect')(1L,1L,80L,24L))
    x$buffer <- ScreenBuffer$new(80L,24L)
    x
  },function(x) {
    if (op=='layout') internal('layout_tree')(x$a$screen,internal('rect')(1L,1L,80L,24L))
    else internal('paint_tree')(x$a$screen,x$buffer)
  })
}
measure('focusable-traversal-100-tabs',1000L,function() {
  test_app(app(do.call(vertical,lapply(1:1000,function(i) button(as.character(i))))))
},function(p) {for(i in 1:100) p$press('tab'); stopifnot(!is.null(p$app$focused))},function(p) p$stop())
for(n in c(1L,100L,10000L)) measure('combined-input-parser',n,function() {
  list(p=internal('KeyParser')$new(),text=paste(rep('\t\r',n),collapse=''))
},function(x) stopifnot(length(x$p$feed(x$text))==2L*n))
for(op in c('cache-hit','replacement')) measure(paste0('source-',op),10000000L,function() {
  src <- table_source(10000000L,'x',function(start,count,columns) data.frame(x=seq.int(start,length.out=count)))
  t <- data_table(src)
  a <- app(t); render_widget(a,80,24)
  list(a=a,t=t,s=src)
},function(x) {
  if(op=='replacement') x$t$set_data(x$s)
  render_widget(x$a,80,24)
  if(op=='cache-hit') stopifnot(x$t$source_stats()$cache_hits>0L)
})
