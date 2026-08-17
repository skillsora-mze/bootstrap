[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$RootDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
. (Join-Path $RootDir 'scripts/lib/windows.ps1')

$required = @('git.exe','aws.exe','sam.exe','az.cmd','azd.exe','terraform.exe','packer.exe','vagrant.exe','kubectl.exe','helm.exe','kind.exe','k9s.exe','kubectx.exe','docker.exe')
$failed = $false
Write-Section 'Workstation verification'
Refresh-ProcessPath
foreach ($cmd in $required) {
    if (Get-Command $cmd -ErrorAction SilentlyContinue) { Write-Success $cmd }
    else { Write-Warn "$cmd missing"; $failed = $true }
}
if (Get-Command docker.exe -ErrorAction SilentlyContinue) {
    & docker.exe info *> $null
    if ($LASTEXITCODE -ne 0) { Write-Warn 'Container engine unavailable'; $failed = $true }
}
if ($failed) { exit 1 }
