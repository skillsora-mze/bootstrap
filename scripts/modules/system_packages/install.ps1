[CmdletBinding()]
param([Parameter(Mandatory)][string]$RootDir)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
& (Join-Path $RootDir 'scripts/windows/install-packages.ps1') -RootDir $RootDir
