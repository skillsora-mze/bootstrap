[CmdletBinding()]
param([Parameter(Mandatory)][string]$RootDir)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $RootDir 'scripts/lib/windows.ps1')

$versions = Get-VersionConfig -Path (Join-Path $RootDir 'config/versions.env')

Install-WingetPackage -Id 'Amazon.AWSCLI'
$samVersion = $versions.SAM_CLI_VERSION.TrimStart('v')
Install-WingetPackage -Id 'Amazon.SAM-CLI' -Version $samVersion
Assert-Command -Name 'aws'
Assert-Command -Name 'sam'
Invoke-NativeCommand -FilePath 'aws' -ArgumentList @('--version') | Out-Null
Invoke-NativeCommand -FilePath 'sam' -ArgumentList @('--version') | Out-Null
Write-Success 'AWS tooling validated'
