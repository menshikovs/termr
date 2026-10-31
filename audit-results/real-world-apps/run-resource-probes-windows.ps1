Remove-Item Env:LC_ALL,Env:LC_CTYPE,Env:LC_COLLATE,Env:LC_MONETARY,Env:LC_TIME -ErrorAction SilentlyContinue
$env:TERMR_USE_INSTALLED='1'
foreach ($kind in @('mirai','pool','model')) {
  & 'C:/Program Files/R/R-4.6.1/bin/Rscript.exe' integration-apps/automation/resource-probe.R --kind=$kind *> "audit-results/real-world-apps/resource-probe-$kind.log"
  $LASTEXITCODE | Set-Content "audit-results/real-world-apps/resource-probe-$kind.exit"
}
