param(
  [ValidateSet('showcase','analytics','monitor')][string]$App='showcase',
  [ValidateSet('terminal','web','headless')][string]$Mode='terminal'
)
$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
$rscript=Get-Command Rscript.exe -ErrorAction SilentlyContinue
$executable=if($rscript){$rscript.Source}else{'C:/Program Files/R/R-4.6.1/bin/Rscript.exe'}
if(!(Test-Path -LiteralPath $executable)){throw 'Rscript was not found. Put your R installation on PATH.'}
Push-Location -LiteralPath $root
try {
  if($Mode -eq 'terminal'){Write-Host 'The interface runs in this terminal. Press q to close it.'}
  # Native startup warnings must not become terminating PowerShell exceptions.
  $ErrorActionPreference='Continue'
  & $executable integration-apps/run.R --app=$App --mode=$Mode
  $code=$LASTEXITCODE
} finally {Pop-Location}
exit $code
