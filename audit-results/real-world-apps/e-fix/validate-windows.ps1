$ErrorActionPreference='Continue'
Remove-Item Env:LC_ALL,Env:LC_CTYPE,Env:LC_COLLATE,Env:LC_MONETARY,Env:LC_TIME -ErrorAction SilentlyContinue
$root='C:/programming_pj/r_textualize'
$out="$root/audit-results/real-world-apps/e-fix"
$env:R_LIBS_USER="$root/integration-apps/.deps/current-windows;$root/integration-apps/.deps/R-windows;C:/Users/User001/AppData/Local/R/win-library/4.6"
$env:TERMR_PROJECT_ROOT=$root
$env:NOT_CRAN='true'
$env:_R_CHECK_FORCE_SUGGESTS_='false'
$env:TERMR_E_ARTIFACTS="$out/tests-final-windows"
& 'C:/Program Files/R/R-4.6.1/bin/Rscript.exe' integration-apps/automation/run-app-tests.R all *> "$out/tests-final-windows.log"
$LASTEXITCODE | Set-Content "$out/tests-final-windows.exit"
& 'C:/Program Files/R/R-4.6.1/bin/Rscript.exe' tools/dev.R test *> "$out/core-windows.log"
$LASTEXITCODE | Set-Content "$out/core-windows.exit"
New-Item -ItemType Directory -Force -Path "$out/check-windows" | Out-Null
Set-Location "$out/check-windows"
& 'C:/Program Files/R/R-4.6.1/bin/R.exe' CMD build --no-build-vignettes ../package-source *> build.log
$LASTEXITCODE | Set-Content build.exit
if($LASTEXITCODE -eq 0){
  & 'C:/Program Files/R/R-4.6.1/bin/R.exe' CMD check --no-manual --no-build-vignettes termr_1.0.1.tar.gz *> check.log
  $LASTEXITCODE | Set-Content check.exit
}
