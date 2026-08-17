[CmdletBinding()]
param([Parameter(Mandatory)][string]$RootDir)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $RootDir 'scripts/lib/windows.ps1')

Install-WingetPackage -Id 'Microsoft.AzureCLI'
Install-WingetPackage -Id 'Microsoft.Azd'
Assert-Command -Name 'az.cmd'
Assert-Command -Name 'azd.exe'
& az.cmd version
& azd.exe version
Write-Success 'Azure tooling validated'
