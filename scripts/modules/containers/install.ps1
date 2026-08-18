[CmdletBinding()]
param([Parameter(Mandatory)][string]$RootDir)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $RootDir 'scripts/lib/windows.ps1')

Write-Info 'Configuring Rancher Desktop with Moby (dockerd)'

Assert-WslReady

$versions = Get-VersionConfig -Path (Join-Path $RootDir 'config/versions.env')

Install-WingetPackage -Id 'SUSE.RancherDesktop' -Version $versions.RANCHER_DESKTOP_VERSION

Refresh-ProcessPath

$rdctlCommand = Get-Command rdctl.exe -ErrorAction SilentlyContinue
$rdctlPath = if ($rdctlCommand) { $rdctlCommand.Source } else { $null }

if (-not $rdctlPath) {
    $candidate = Join-Path $env:ProgramFiles 'Rancher Desktop/resources/resources/win32/bin/rdctl.exe'
    if (Test-Path -LiteralPath $candidate -PathType Leaf) {
        $rdctlPath = $candidate
    }
}

if (-not $rdctlPath) {
    throw 'Rancher Desktop installed but rdctl.exe was not found.'
}

# First launch must not block the bootstrap process.
$rancherDesktopExe = Join-Path $env:ProgramFiles 'Rancher Desktop/Rancher Desktop.exe'

if (-not (Get-Process -Name 'Rancher Desktop' -ErrorAction SilentlyContinue)) {
    if (-not (Test-Path -LiteralPath $rancherDesktopExe -PathType Leaf)) {
        throw 'Rancher Desktop executable was not found.'
    }

    Write-Info 'Starting Rancher Desktop'
    Start-Process -FilePath $rancherDesktopExe | Out-Null
}

# Wait for the Rancher Desktop API to become available.
$deadline = (Get-Date).AddMinutes(5)
$rdctlReady = $false

do {
    & $rdctlPath list-settings *> $null

    if ($LASTEXITCODE -eq 0) {
        $rdctlReady = $true
        break
    }

    Start-Sleep -Seconds 3
} while ((Get-Date) -lt $deadline)

if (-not $rdctlReady) {
    throw 'Rancher Desktop did not become ready within 5 minutes.'
}

# Standard workstation runtime:
# - Moby exposes the Docker API required by Docker-compatible tooling.
# - Kubernetes is provided by kind, not Rancher Desktop.
& $rdctlPath set --container-engine.name=moby --kubernetes-enabled=false | Out-Null

Refresh-ProcessPath

Assert-Command -Name 'docker.exe'

# Docker Desktop may leave desktop-linux selected after migration.
# Rancher Desktop Moby exposes its engine through the default context.
$currentContext = (& docker.exe context show 2>$null).Trim()

if ($currentContext -ne 'default') {
    Write-Info "Switching Docker context from '$currentContext' to 'default'"
    & docker.exe context use default | Out-Null

    if ($LASTEXITCODE -ne 0) {
        throw 'Unable to switch Docker context to default.'
    }
}

# Wait for the Moby engine to answer Docker API requests.
$deadline = (Get-Date).AddMinutes(5)
$dockerReady = $false

do {
    & docker.exe info *> $null

    if ($LASTEXITCODE -eq 0) {
        $dockerReady = $true
        break
    }

    Start-Sleep -Seconds 3
} while ((Get-Date) -lt $deadline)

if (-not $dockerReady) {
    throw 'Rancher Desktop Moby engine did not become ready within 5 minutes.'
}

& docker.exe --version
& docker.exe compose version

Write-Success 'Rancher Desktop / Moby runtime validated'
