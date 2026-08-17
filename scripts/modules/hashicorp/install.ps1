[CmdletBinding()]
param([Parameter(Mandatory)][string]$RootDir)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $RootDir 'scripts/lib/windows.ps1')

Install-WingetPackage -Id 'Hashicorp.Terraform'
Install-WingetPackage -Id 'Hashicorp.Packer'
Install-WingetPackage -Id 'HashiCorp.Vagrant'
foreach ($cmd in @('terraform.exe','packer.exe','vagrant.exe')) { Assert-Command -Name $cmd }
& terraform.exe version
& packer.exe version
& vagrant.exe --version
Write-Warn 'Ansible control-node execution is not supported natively on Windows; use WSL2 for Ansible labs.'
Write-Success 'HashiCorp tooling validated'
