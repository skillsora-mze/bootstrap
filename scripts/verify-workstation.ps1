[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$RootDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
. (Join-Path $RootDir 'scripts/lib/windows.ps1')

$configPath = Join-Path $RootDir 'config/bootstrap.yaml'
$enabled = @(Get-EnabledModules -ConfigPath $configPath)
$commandsByModule = @{
    system_packages = @('git','gh','pwsh','python','uv','go','jq','yq','rg','starship')
    containers      = @('docker')
    aws             = @('aws','sam')
    azure           = @('az','azd')
    hashicorp       = @('terraform','packer','vagrant')
    kubernetes      = @('kubectl','helm','kind','k9s','kubectx')
    terminal        = @()
}

$failed = $false
Write-Section 'Workstation verification'
Refresh-ProcessPath
foreach ($module in $enabled) {
    foreach ($cmd in $commandsByModule[$module]) {
        if (Get-Command $cmd -ErrorAction SilentlyContinue) { Write-Success "$module/$cmd" }
        else { Write-Warn "$module/$cmd missing"; $failed = $true }
    }
}

if ($enabled -contains 'containers' -and (Get-Command docker -ErrorAction SilentlyContinue)) {
    $docker = Invoke-NativeCommand -FilePath 'docker' -ArgumentList @('info') -AllowFailure -Quiet
    if ($docker.ExitCode -ne 0) { Write-Warn 'Container engine unavailable'; $failed = $true }
}

if ($failed) { exit 1 }
Write-Success 'Workstation verification completed'
