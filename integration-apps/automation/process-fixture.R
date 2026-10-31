mode <- commandArgs(TRUE)[[1L]]
if (mode == 'quiet') quit(status = 0L)
if (mode == 'stderr') {cat('controlled stderr\n',file=stderr());quit(status=0L)}
if (mode == 'exit7') quit(status=7L)
if (mode == 'hang') {cat('READY fixture\n');flush(stdout());Sys.sleep(60)}
if (mode == 'child') {
  child <- processx::process$new(file.path(R.home('bin'),'Rscript'),
    c('integration-apps/automation/process-fixture.R','hang'),stdout='|',stderr='|',cleanup_tree=TRUE)
  cat(sprintf('CHILD %d\n',child$get_pid()));flush(stdout());Sys.sleep(60)
}
