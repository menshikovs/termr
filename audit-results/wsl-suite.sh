set -e
rm -rf ~/audit/src2 && mkdir -p ~/audit/src2
cd /mnt/c/programming_pj/r_textualize
tar --exclude=.git --exclude=audit-results --exclude=site --exclude=docs --exclude=pkgdown -cf - . | tar -xf - -C ~/audit/src2
cd ~/audit/src2
TERMR_FULL_TESTS=true Rscript -e "options(testthat.progress.max_fails=1000); r<-testthat::test_local('.', reporter='summary', stop_on_failure=FALSE); df<-as.data.frame(r); cat(sprintf('TOTAL %d tests, %d failed, %d errors, %d skipped, %d warnings\n', sum(df\$nb), sum(df\$failed), sum(df\$error), sum(df\$skipped), sum(df\$warning)))" > ~/audit/suite-wsl.log 2>&1
tail -40 ~/audit/suite-wsl.log
