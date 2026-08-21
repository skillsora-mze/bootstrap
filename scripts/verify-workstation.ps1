[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$RootDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
. (Join-Path $RootDir 'scripts/lib/windows.ps1')

$configPath = Join-Path $RootDir 'config/bootstrap.yaml'
$enabled = @(Get-EnabledModules -ConfigPath $configPath)
$containerCapability = Get-WindowsLocalContainerCapability
$kubernetesCommands = @('kubectl','helm','k9s','kubectx')
$containerCommands = @()
if ($containerCapability.Supported) {
    $kubernetesCommands += 'kind'
    $containerCommands += 'docker'
}
$commandsByModule = @{
    system_packages = @('git','gh','pwsh','python','uv','go','jq','yq','rg','starship')
    containers      = $containerCommands
    aws             = @('aws','sam')
    azure           = @('az','azd')
    hashicorp       = @('terraform','packer','vagrant')
    kubernetes      = $kubernetesCommands
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

if ($enabled -contains 'containers' -and -not $containerCapability.Supported) {
    Write-Warn "containers/local-runtime skipped: $($containerCapability.Reason)"
}
elseif ($enabled -contains 'containers' -and (Get-Command docker -ErrorAction SilentlyContinue)) {
    $dockerOs = Invoke-NativeCommand -FilePath 'docker' -ArgumentList @('info','--format','{{.OSType}}') -AllowFailure -Quiet
    if ($dockerOs.ExitCode -ne 0) {
        Write-Warn 'Container engine unavailable'
        $failed = $true
    }
    elseif (($dockerOs.Output | Select-Object -First 1).Trim() -ne 'linux') {
        Write-Warn 'Docker is not using the required Linux container engine'
        $failed = $true
    }
    else {
        Write-Success 'containers/docker-linux-engine'
    }

    $compose = Invoke-NativeCommand -FilePath 'docker' -ArgumentList @('compose','version') -AllowFailure -Quiet
    if ($compose.ExitCode -ne 0) { Write-Warn 'Docker Compose unavailable'; $failed = $true }
    else { Write-Success 'containers/docker-compose' }

    $hello = Invoke-NativeCommand -FilePath 'docker' -ArgumentList @('run','--rm','hello-world') -AllowFailure -Quiet
    if ($hello.ExitCode -ne 0 -or (($hello.Output -join [Environment]::NewLine) -notmatch 'Hello from Docker!')) {
        Write-Warn 'Docker hello-world smoke test failed'
        $failed = $true
    }
    else { Write-Success 'containers/hello-world' }
}

if ($failed) { exit 1 }
Write-Success 'Workstation verification completed'
