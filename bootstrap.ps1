[CmdletBinding()]
param(
    [switch]$Interactive,
    [switch]$NonInteractive
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($Interactive -and $NonInteractive) {
    throw 'Use either -Interactive or -NonInteractive, not both.'
}

$RootDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $RootDir 'scripts/lib/windows.ps1')

Write-Section 'Workstation Bootstrap'
Assert-SupportedWindowsPlatform
Assert-WinGet

$configPath = Join-Path $RootDir 'config/bootstrap.yaml'
$version = Get-BootstrapVersion -ConfigPath $configPath
$enabledModules = @(Get-EnabledModules -ConfigPath $configPath)

$useInteractive = $Interactive -or (-not $NonInteractive -and -not $env:CI -and [Environment]::UserInteractive)
if ($useInteractive) {
    $enabledModules = @(Select-ModulesInteractive -DefaultModules $enabledModules)
}

Write-Info "Version: $version"
Write-Info 'Operating system: windows'
Write-Info 'Architecture: amd64'
Write-Info "Windows build: $([Environment]::OSVersion.Version.Build)"
Write-Info "Selected modules: $($enabledModules -join ', ')"

if ($enabledModules -contains 'containers') {
    Assert-WslReady
}

foreach ($module in $enabledModules) {
    Write-Section "Module: $module"
    $script = Join-Path $RootDir "scripts/modules/$module/install.ps1"
    if (-not (Test-Path -LiteralPath $script -PathType Leaf)) {
        throw "Module '$module' is not implemented for Windows: $script"
    }
    & $script -RootDir $RootDir
    Write-Success "Module '$module' completed"
}

Write-Success "Workstation Bootstrap $version completed"
Write-Info 'Open a new PowerShell terminal before using newly installed commands.'
