[CmdletBinding()]
param([Parameter(Mandatory)][string]$RootDir)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $RootDir 'scripts/lib/windows.ps1')

Install-WingetPackage -Id 'Microsoft.AzureCLI'
# Microsoft.Azd uses WinGet package-version numbering that does not map 1:1
# to the azd product version (for example 1.31.100 vs azd 1.31.1).
# Follow the stable WinGet channel on Windows, as recommended by Microsoft.
Install-WingetPackage -Id 'Microsoft.Azd'

Assert-Command -Name 'az'
Assert-Command -Name 'azd'
Invoke-NativeCommand -FilePath 'az' -ArgumentList @('version') | Out-Null
Invoke-NativeCommand -FilePath 'azd' -ArgumentList @('version') | Out-Null
Write-Success 'Azure tooling validated'
