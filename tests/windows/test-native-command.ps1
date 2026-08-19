Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$RootDir = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
. (Join-Path $RootDir 'scripts/lib/windows.ps1')

$success = Invoke-NativeCommand -FilePath 'cmd.exe' -ArgumentList @('/d','/s','/c','echo harmless-warning 1>&2 & exit /b 0') -Quiet
if ($success.ExitCode -ne 0) { throw 'Native stderr with exit code 0 must be treated as success.' }

$failure = Invoke-NativeCommand -FilePath 'cmd.exe' -ArgumentList @('/d','/s','/c','echo expected-failure 1>&2 & exit /b 7') -AllowFailure -Quiet
if ($failure.ExitCode -ne 7) { throw "Expected native exit code 7, got $($failure.ExitCode)." }

$global:LASTEXITCODE = 0
Write-Host 'Windows native-command tests passed'
exit 0
