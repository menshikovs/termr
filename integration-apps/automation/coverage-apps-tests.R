# Runs inside covr's instrumented app environment. Keep the real native workload
# uninstrumented: its body runs in another R process, not this counter registry.
monitor_work <- get('monitor_work', envir = .GlobalEnv)
for (ink in c(FALSE, TRUE)) {
  demo <- workbench_app(use_inkr = ink, chart_mode = 'ascii')
  p <- termr::test_app(demo$app, width = 100, height = 30)
  tryCatch({
    p$press('f2', 'f2', 'alt+s', 'alt+s', 'f4', 'f7', 'f8', 'escape', 'f9', 'escape')
    for (action in c('filter', 'sort', 'find', 'apply-edit', 'reset', 'sample')) demo$action(action)
    demo$action('confirm-reset'); p$press('escape')
    p$resize(40,18); p$press('alt+c','right','enter'); p$resize(100,30)
    for (i in 1:5) {p$query_one('#chart-tabs')$activate(i);p$step()}
    stopifnot(demo$table$row_count > 0L)
  }, finally = {p$stop();demo$close()})
}
demo <- analytics_terminal(); p <- termr::test_app(demo$app)
tryCatch(p$press('f2','alt+s','f4','f4','f5'),finally={p$stop();demo$close()})
dash <- analytics_dashboard()
tryCatch(shiny::testServer(dash$server,{
  output$live; session$setInputs(next_sample=1,source=1);session$flushReact()
  session$setInputs(empty=1);session$flushReact();session$setInputs(empty=2,invalid=1);session$flushReact()
  stopifnot(nrow(session$userData$frame())>0L)
}),finally=dash$close())
demo <- distributed_monitor(1L);p <- termr::test_app(demo$app,width=100,height=30)
tryCatch({
  p$press('n','e','l','c')
  deadline <- proc.time()[['elapsed']]+15
  while (demo$model$pool$diagnostics()$pending && proc.time()[['elapsed']]<deadline) {p$advance(.05);Sys.sleep(.005)}
  p$focus('#tasks');p$press('enter');stopifnot(length(demo$app$screens)==2L);p$press('escape')
  p$press('d','r');p$advance(.1);p$resize(42,18)
  stopifnot(!demo$model$pool$diagnostics()$pending)
},finally={p$stop();demo$close()})
