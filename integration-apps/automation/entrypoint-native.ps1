param([string]$App,[string]$Out,[string]$Scenario='normal')
$ErrorActionPreference='Continue'
& 'C:/Program Files/R/R-4.6.1/bin/Rscript.exe' integration-apps/run.R --app=$App --mode=terminal --scenario=$Scenario 2> "$Out/stderr.log"
$code=$LASTEXITCODE
$code | Set-Content "$Out/exit-code.txt"
exit $code
