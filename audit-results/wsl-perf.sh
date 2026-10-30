export R_LIBS=$HOME/audit/lib
cd ~/audit
hyperfine -w 2 -r 10 'Rscript -e "invisible(1)"' 'Rscript -e "library(termr)"' 'Rscript -e "library(termr); a <- app(label(\"x\")); p <- test_app(a, 80, 24); p$stop()"' 2>&1 | grep -E "Benchmark|Time|Range"
