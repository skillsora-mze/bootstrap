[CmdletBinding()]
param([Parameter(Mandatory)][string]$RootDir)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $RootDir 'scripts/lib/windows.ps1')

function Invoke-ProbeWithTimeout {
    param(
        [Parameter(Mandatory)][string]$FilePath,
        [string[]]$ArgumentList = @(),
        [int]$TimeoutSeconds = 10
    )

    if ($TimeoutSeconds -lt 1) { throw 'Probe timeout must be at least one second.' }

    $stdout = [IO.Path]::GetTempFileName()
    $stderr = [IO.Path]::GetTempFileName()
    try {
        $process = Start-Process -FilePath $FilePath -ArgumentList $ArgumentList -NoNewWindow -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
        $completed = $process.WaitForExit($TimeoutSeconds * 1000)
        if (-not $completed) {
            Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
            return [pscustomobject]@{
                ExitCode = 124
                Output = @()
                TimedOut = $true
            }
        }

        # Ensure redirected output has been fully flushed before reading it.
        $process.WaitForExit()
        $output = @()
        if (Test-Path -LiteralPath $stdout) { $output += @(Get-Content -LiteralPath $stdout -ErrorAction SilentlyContinue) }
        if (Test-Path -LiteralPath $stderr) { $output += @(Get-Content -LiteralPath $stderr -ErrorAction SilentlyContinue) }
        return [pscustomobject]@{
            ExitCode = $process.ExitCode
            Output = @($output | ForEach-Object { $_.ToString() })
            TimedOut = $false
        }
    }
    finally {
        Remove-Item -LiteralPath $stdout, $stderr -Force -ErrorAction SilentlyContinue
    }
}

function Get-RancherSettings {
    param([Parameter(Mandatory)][string]$RdctlPath)

    $result = Invoke-ProbeWithTimeout -FilePath $RdctlPath -ArgumentList @('list-settings') -TimeoutSeconds 10
    if ($result.TimedOut -or $result.ExitCode -ne 0 -or $result.Output.Count -eq 0) { return $null }
    try {
        return (($result.Output -join [Environment]::NewLine) | ConvertFrom-Json)
    }
    catch {
        return $null
    }
}

function Assert-ProbeSucceeded {
    param(
        [Parameter(Mandatory)]$Result,
        [Parameter(Mandatory)][string]$Description
    )
    if ($Result.TimedOut) { throw "$Description timed out." }
    if ($Result.ExitCode -ne 0) {
        $detail = $Result.Output -join [Environment]::NewLine
        throw "$Description failed with exit code $($Result.ExitCode).`n$detail"
    }
}

Write-Info 'Configuring Rancher Desktop with Moby (dockerd)'
Assert-WslReady

$versions = Get-VersionConfig -Path (Join-Path $RootDir 'config/versions.env')
Install-WingetPackage -Id 'SUSE.RancherDesktop' -Version $versions.RANCHER_DESKTOP_VERSION
Refresh-ProcessPath

$rdctlCommand = Get-Command rdctl.exe -ErrorAction SilentlyContinue
$rdctlPath = if ($rdctlCommand) { $rdctlCommand.Source } else { $null }
if (-not $rdctlPath) {
    $candidate = Join-Path $env:ProgramFiles 'Rancher Desktop/resources/resources/win32/bin/rdctl.exe'
    if (Test-Path -LiteralPath $candidate -PathType Leaf) { $rdctlPath = $candidate }
}
if (-not $rdctlPath) { throw 'Rancher Desktop installed but rdctl.exe was not found.' }

# Avoid restarting an already-ready runtime on idempotence runs.
$settings = Get-RancherSettings -RdctlPath $rdctlPath
if ($settings) {
    Write-Info 'Rancher Desktop already running'
}
else {
    $startArgs = @(
        'start',
        '--application.start-in-background=true',
        '--application.updater.enabled=false',
        '--container-engine.name=moby',
        '--kubernetes.enabled=false'
    )
    Write-Info 'Starting Rancher Desktop in background'
    Start-Process -FilePath $rdctlPath -ArgumentList $startArgs -WindowStyle Hidden | Out-Null

    $deadline = (Get-Date).AddMinutes(5)
    $attempt = 0
    do {
        $attempt++
        $settings = Get-RancherSettings -RdctlPath $rdctlPath
        if ($settings) { break }
        if (($attempt % 2) -eq 0) { Write-Info 'Waiting for Rancher Desktop readiness...' }
        Start-Sleep -Seconds 3
    } while ((Get-Date) -lt $deadline)
}

if (-not $settings) {
    throw 'Rancher Desktop did not become ready within 5 minutes. Each rdctl readiness probe is individually time-bounded.'
}

# Enforce the training baseline even if Rancher Desktop was previously configured.
$setResult = Invoke-ProbeWithTimeout -FilePath $rdctlPath -ArgumentList @('set','--application.updater.enabled=false','--container-engine.name=moby','--kubernetes-enabled=false') -TimeoutSeconds 30
Assert-ProbeSucceeded -Result $setResult -Description 'Rancher Desktop settings update'

# Rancher Desktop exposes CLI utilities in ~/.rd/bin on Windows installations.
$rdBin = Join-Path $HOME '.rd\bin'
if (Test-Path -LiteralPath $rdBin -PathType Container) {
    Add-UserPathEntry -Path $rdBin
}

Refresh-ProcessPath
Assert-Command -Name 'docker'

$currentContextResult = Invoke-ProbeWithTimeout -FilePath 'docker' -ArgumentList @('context','show') -TimeoutSeconds 10
Assert-ProbeSucceeded -Result $currentContextResult -Description 'Docker context query'
$currentContext = if ($currentContextResult.Output.Count -gt 0) { $currentContextResult.Output[0].Trim() } else { '' }
if ($currentContext -ne 'default') {
    Write-Info "Switching Docker context from '$currentContext' to 'default'"
    $contextUseResult = Invoke-ProbeWithTimeout -FilePath 'docker' -ArgumentList @('context','use','default') -TimeoutSeconds 15
    Assert-ProbeSucceeded -Result $contextUseResult -Description 'Docker context switch'
}

$deadline = (Get-Date).AddMinutes(5)
$dockerReady = $false
$attempt = 0
do {
    $attempt++
    $dockerInfo = Invoke-ProbeWithTimeout -FilePath 'docker' -ArgumentList @('info') -TimeoutSeconds 10
    if (-not $dockerInfo.TimedOut -and $dockerInfo.ExitCode -eq 0) {
        $dockerReady = $true
        break
    }
    if (($attempt % 2) -eq 0) { Write-Info 'Waiting for Rancher Desktop Moby engine...' }
    Start-Sleep -Seconds 3
} while ((Get-Date) -lt $deadline)

if (-not $dockerReady) {
    throw 'Rancher Desktop Moby engine did not become ready within 5 minutes. Each docker readiness probe is individually time-bounded.'
}

$dockerVersion = Invoke-ProbeWithTimeout -FilePath 'docker' -ArgumentList @('--version') -TimeoutSeconds 15
Assert-ProbeSucceeded -Result $dockerVersion -Description 'Docker version check'
$composeVersion = Invoke-ProbeWithTimeout -FilePath 'docker' -ArgumentList @('compose','version') -TimeoutSeconds 15
Assert-ProbeSucceeded -Result $composeVersion -Description 'Docker Compose version check'
Write-Success 'Rancher Desktop / Moby runtime validated'
