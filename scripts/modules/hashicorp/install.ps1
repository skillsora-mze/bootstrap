[CmdletBinding()]
param([Parameter(Mandatory)][string]$RootDir)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $RootDir 'scripts/lib/windows.ps1')

Install-WingetPackage -Id 'Hashicorp.Terraform'
Install-WingetPackage -Id 'Hashicorp.Packer'
Install-WingetPackage -Id 'HashiCorp.Vagrant'
foreach ($cmd in @('terraform','packer','vagrant')) { Assert-Command -Name $cmd }
Invoke-NativeCommand -FilePath 'terraform' -ArgumentList @('version') | Out-Null
Invoke-NativeCommand -FilePath 'packer' -ArgumentList @('version') | Out-Null
Invoke-NativeCommand -FilePath 'vagrant' -ArgumentList @('--version') | Out-Null
Write-Warn 'Ansible control-node execution is not supported natively on Windows; use WSL2 for Ansible labs.'
Write-Success 'HashiCorp tooling validated'
