Remove-Item Env:LC_ALL,Env:LC_CTYPE,Env:LC_COLLATE,Env:LC_MONETARY,Env:LC_TIME -ErrorAction SilentlyContinue
& 'C:/Program Files/R/R-4.6.1/bin/Rscript.exe' tools/integration/run-all.R --mode=process,lint,profile,benchmark --timeout=240 --out=audit-results/real-world-apps/e-fix/automation-windows *> audit-results/real-world-apps/e-fix/automation-windows.log
$LASTEXITCODE | Set-Content audit-results/real-world-apps/e-fix/automation-windows.exit
