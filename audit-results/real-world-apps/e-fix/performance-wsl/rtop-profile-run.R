Rprof(Sys.getenv('TERMR_E_RTOP_PROFILE'),interval=.01)
tryCatch(source('integration-apps/legacy-rtop/run.R'),finally=Rprof(NULL))
