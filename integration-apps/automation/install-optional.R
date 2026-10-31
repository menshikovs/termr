lib <- 'integration-apps/.deps/R-linux'
dir.create(lib,recursive=TRUE,showWarnings=FALSE)
.libPaths(c(normalizePath(lib),.libPaths()))
options(repos=c(CRAN='https://cloud.r-project.org'),timeout=240)
needed <- c('nanonext','mirai')
needed <- needed[!vapply(needed,requireNamespace,TRUE,quietly=TRUE)]
if(length(needed)) install.packages(needed,lib=lib,Ncpus=2L)
stopifnot(all(vapply(c('nanonext','mirai'),requireNamespace,TRUE,quietly=TRUE)))
print(vapply(c('nanonext','mirai'),function(p) as.character(packageVersion(p)),''))
