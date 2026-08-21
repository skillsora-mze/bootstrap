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
$windowsArch = switch (Get-WindowsOsArchitecture) {
    'AMD64' { 'amd64' }
    'ARM64' { 'arm64' }
    default { (Get-WindowsOsArchitecture).ToLowerInvariant() }
}
Write-Info "Architecture: $windowsArch"
Write-Info "Windows build: $([Environment]::OSVersion.Version.Build)"
$containerCapability = Get-WindowsLocalContainerCapability
Write-Info "Runtime profile: $($containerCapability.Profile)"
Write-Info "Selected modules: $($enabledModules -join ', ')"

if ($enabledModules -contains 'containers') {
    if ($containerCapability.Supported) {
        Assert-WslReady
    }
    else {
        Write-Warn $containerCapability.Reason
    }
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
