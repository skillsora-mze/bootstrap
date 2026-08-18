[CmdletBinding()]
param([Parameter(Mandatory)][string]$RootDir)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $RootDir 'scripts/lib/windows.ps1')

$versions = Get-VersionConfig -Path (Join-Path $RootDir 'config/versions.env')

Install-WingetPackage -Id 'Microsoft.AzureCLI'
Install-WingetPackage -Id 'Microsoft.Azd' -Version $versions.AZD_VERSION
Assert-Command -Name 'az'
Assert-Command -Name 'azd'
Invoke-NativeCommand -FilePath 'az' -ArgumentList @('version') | Out-Null
Invoke-NativeCommand -FilePath 'azd' -ArgumentList @('version') | Out-Null
Write-Success 'Azure tooling validated'
