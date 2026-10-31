$ErrorActionPreference = 'Continue'
Remove-Item Env:LC_ALL,Env:LC_CTYPE,Env:LC_COLLATE,Env:LC_MONETARY,Env:LC_TIME -ErrorAction SilentlyContinue
$eRscript = 'C:\Program Files\R\R-4.6.1\bin\Rscript.exe'
foreach ($eApp in @('showcase', 'analytics', 'monitor')) {
  & $eRscript integration-apps/run.R --app=$eApp --mode=headless *> "audit-results/real-world-apps/smoke-$eApp-windows.log"
  $LASTEXITCODE | Set-Content "audit-results/real-world-apps/smoke-$eApp-windows.exit"
  Write-Output "$eApp exit: $LASTEXITCODE"
}
