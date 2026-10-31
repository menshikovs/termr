Remove-Item Env:LC_ALL,Env:LC_CTYPE,Env:LC_COLLATE,Env:LC_MONETARY,Env:LC_TIME -ErrorAction SilentlyContinue
$root='C:/programming_pj/r_textualize'
$env:R_LIBS_USER="$root/integration-apps/.deps/current-windows;$root/integration-apps/.deps/R-windows;C:/Users/User001/AppData/Local/R/win-library/4.6"
$env:NOT_CRAN='true'
$env:_R_CHECK_FORCE_SUGGESTS_='false'
$target="$root/audit-results/real-world-apps/e-fix/final-check-windows"
New-Item -ItemType Directory -Force -Path $target | Out-Null
Set-Location $target
& 'C:/Program Files/R/R-4.6.1/bin/R.exe' CMD build --no-build-vignettes ../package-source *> build.log
$LASTEXITCODE | Set-Content build.exit
if($LASTEXITCODE -eq 0){
  & 'C:/Program Files/R/R-4.6.1/bin/R.exe' CMD check --no-manual --no-build-vignettes termr_1.0.1.tar.gz *> check.log
  $LASTEXITCODE | Set-Content check.exit
}
