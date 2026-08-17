[CmdletBinding()]
param([Parameter(Mandatory)][string]$RootDir)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $RootDir 'scripts/lib/windows.ps1')

Install-WingetPackage -Id 'Amazon.AWSCLI'
Install-WingetPackage -Id 'Amazon.SAM-CLI'
Assert-Command -Name 'aws.exe'
Assert-Command -Name 'sam.exe'
& aws.exe --version
& sam.exe --version
Write-Success 'AWS tooling validated'
