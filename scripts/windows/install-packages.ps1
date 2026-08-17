[CmdletBinding()]
param([Parameter(Mandatory)][string]$RootDir)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $RootDir 'scripts/lib/windows.ps1')

$manifest = Import-PowerShellDataFile (Join-Path $RootDir 'packages/windows/packages.psd1')
foreach ($package in $manifest.SystemPackages) {
    Install-WingetPackage -Id $package.Id
}
foreach ($package in $manifest.SystemPackages) {
    Assert-Command -Name $package.Command
}
Write-Success 'Windows system packages validated'
