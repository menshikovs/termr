$ErrorActionPreference = 'Continue'
$h1root = 'C:\programming_pj\r_textualize'
Set-Location -LiteralPath $h1root
$h1audit = Join-Path $h1root 'audit-results\hardening\h3-performance\final-validation-ring'
$h1r = 'C:\Program Files\R\R-4.6.1\bin\R.exe'
$h1script = 'C:\Program Files\R\R-4.6.1\bin\Rscript.exe'
$h1out = Join-Path $env:TEMP 'termr-h3-ring-validation'
New-Item -ItemType Directory -Force -Path $h1out,(Join-Path $h1audit 'build') | Out-Null
Remove-Item Env:LC_ALL,Env:LC_CTYPE,Env:LC_COLLATE,Env:LC_MONETARY,Env:LC_TIME -ErrorAction SilentlyContinue
$h1optional = Join-Path $env:TEMP 'termr-inkr-integration-library'
$h1normal = 'C:/Users/User001/AppData/Local/R/win-library/4.6'
$env:R_LIBS_USER = "$h1optional;$h1normal"
$env:NOT_CRAN = 'true'
$env:_R_CHECK_FORCE_SUGGESTS_ = 'false'
& $h1script -e "testthat::test_local('.', filter='h3-performance-contracts|h2-|h1-contracts|datatable|native-charts|chart-streams|inkr-integration|streams|mirai|nanonext|plotly', reporter='summary')" *> (Join-Path $h1audit 'focused-windows.log')
$LASTEXITCODE | Set-Content (Join-Path $h1audit 'focused-windows.exit')
$env:R_LIBS_USER = $h1normal
& $h1script audit-results/inkr-integration/run-focused-tests.R *> (Join-Path $h1audit 'optional-free-windows.log')
$LASTEXITCODE | Set-Content (Join-Path $h1audit 'optional-free-windows.exit')
$env:R_LIBS_USER = "$h1optional;$h1normal"
& $h1script tools/dev.R test *> (Join-Path $h1audit 'full-windows.log')
$h1tests = $LASTEXITCODE
$h1tests | Set-Content (Join-Path $h1audit 'full-windows.exit')
Write-Output "Windows full suite exit: $h1tests"
Select-String -Path (Join-Path $h1audit 'full-windows.log') -Pattern '\[ FAIL|TOTAL:'
$h3stage = Get-Content -Raw -LiteralPath (Join-Path $h1root 'audit-results/hardening/h3-performance/ring-stage-path.txt')
Push-Location -LiteralPath $h1out
& $h1r CMD build --no-build-vignettes --no-manual $h3stage *> (Join-Path $h1audit 'build-windows.log')
$h1build = $LASTEXITCODE
$h1build | Set-Content (Join-Path $h1audit 'build-windows.exit')
if ($h1build -ne 0) { Pop-Location; exit $h1build }
$h1archive = Join-Path $h1out 'termr_1.0.1.tar.gz'
Copy-Item -LiteralPath $h1archive -Destination (Join-Path $h1audit 'build\termr_1.0.1.tar.gz')
Get-FileHash -LiteralPath $h1archive -Algorithm SHA256 | Format-List | Out-File -Encoding UTF8 (Join-Path $h1audit 'build-archive-sha256.txt')
Write-Output 'H1 source archive ready.'
$env:NOT_CRAN = 'false'
& $h1r CMD check --no-manual --no-vignettes --output=$h1out $h1archive *> (Join-Path $h1audit 'check-windows-console.log')
$h1check = $LASTEXITCODE
$h1check | Set-Content (Join-Path $h1audit 'check-windows.exit')
Copy-Item -LiteralPath (Join-Path $h1out 'termr.Rcheck\00check.log') -Destination (Join-Path $h1audit 'check-windows.log')
Copy-Item -LiteralPath (Join-Path $h1out 'termr.Rcheck\tests\testthat.Rout') -Destination (Join-Path $h1audit 'check-windows-testthat.Rout')
Pop-Location
Get-Content -LiteralPath (Join-Path $h1audit 'check-windows.log') -Tail 5
if ($h1tests -ne 0 -or $h1check -ne 0) { exit 1 }
exit 0
