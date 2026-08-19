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
            try { $process.WaitForExit() } catch { }
        }

        $output = @()
        if (Test-Path -LiteralPath $stdout) { $output += @(Get-Content -LiteralPath $stdout -ErrorAction SilentlyContinue) }
        if (Test-Path -LiteralPath $stderr) { $output += @(Get-Content -LiteralPath $stderr -ErrorAction SilentlyContinue) }

        return [pscustomobject]@{
            ExitCode = if ($completed) { $process.ExitCode } else { 124 }
            Output = @($output | ForEach-Object { $_.ToString() })
            TimedOut = (-not $completed)
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

function Test-RancherBaseline {
    param([Parameter(Mandatory)]$Settings)

    try {
        return (
            $Settings.containerEngine.name -eq 'moby' -and
            $Settings.kubernetes.enabled -eq $false -and
            $Settings.application.updater.enabled -eq $false
        )
    }
    catch {
        return $false
    }
}

function Assert-ProbeSucceeded {
    param(
        [Parameter(Mandatory)]$Result,
        [Parameter(Mandatory)][string]$Description
    )
    if ($Result.TimedOut) {
        $detail = $Result.Output -join [Environment]::NewLine
        throw "$Description timed out.`n$detail"
    }
    if ($Result.ExitCode -ne 0) {
        $detail = $Result.Output -join [Environment]::NewLine
        throw "$Description failed with exit code $($Result.ExitCode).`n$detail"
    }
}

function Assert-NoCompetingDockerDesktopRuntime {
    $running = @()
    foreach ($name in @('Docker Desktop', 'com.docker.backend')) {
        $running += @(Get-Process -Name $name -ErrorAction SilentlyContinue)
    }

    $dockerService = Get-Service -Name 'com.docker.service' -ErrorAction SilentlyContinue
    if ($running.Count -gt 0 -or ($dockerService -and $dockerService.Status -eq 'Running')) {
        throw 'Docker Desktop is currently running and can conflict with the Rancher Desktop Moby named pipe. Quit Docker Desktop explicitly, then rerun the bootstrap. It will not be stopped automatically.'
    }
}

function Get-RancherDockerPath {
    $candidates = @(
        (Join-Path $HOME '.rd\bin\docker.exe'),
        (Join-Path $env:ProgramFiles 'Rancher Desktop\resources\resources\win32\bin\docker.exe')
    )
    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) { return $candidate }
    }
    throw 'Rancher Desktop is ready but its docker.exe could not be found in the supported Rancher Desktop locations.'
}

function Get-RancherFailureDiagnostics {
    $lines = @()

    $rdProcess = @(Get-Process -Name 'Rancher Desktop' -ErrorAction SilentlyContinue)
    if ($rdProcess.Count -gt 0) {
        $lines += "Rancher Desktop process: running ($($rdProcess.Count) process(es))"
    }
    else {
        $lines += 'Rancher Desktop process: not running'
    }

    $wsl = Invoke-ProbeWithTimeout -FilePath 'wsl.exe' -ArgumentList @('--list','--verbose') -TimeoutSeconds 10
    if (-not $wsl.TimedOut -and $wsl.Output.Count -gt 0) {
        $lines += 'WSL distributions:'
        $lines += $wsl.Output
    }

    $logDir = Join-Path $env:LOCALAPPDATA 'rancher-desktop\logs'
    foreach ($logName in @('background.log','wsl-proxy.log','diagnostics.log')) {
        $logPath = Join-Path $logDir $logName
        if (Test-Path -LiteralPath $logPath -PathType Leaf) {
            $lines += "--- $logName (last 20 lines) ---"
            $lines += @(Get-Content -LiteralPath $logPath -Tail 20 -ErrorAction SilentlyContinue)
        }
    }

    return ($lines -join [Environment]::NewLine)
}

function Wait-RancherSettings {
    param(
        [Parameter(Mandatory)][string]$RdctlPath,
        [Parameter(Mandatory)][datetime]$Deadline
    )

    $attempt = 0
    do {
        $attempt++
        $settings = Get-RancherSettings -RdctlPath $RdctlPath
        if ($settings) { return $settings }
        if (($attempt % 2) -eq 0) { Write-Info 'Waiting for Rancher Desktop readiness...' }
        Start-Sleep -Seconds 3
    } while ((Get-Date) -lt $Deadline)

    return $null
}

Write-Info 'Configuring Rancher Desktop with Moby (dockerd)'
Assert-WslReady

$versions = Get-VersionConfig -Path (Join-Path $RootDir 'config/versions.env')
Install-WingetPackage -Id 'SUSE.RancherDesktop' -Version $versions.RANCHER_DESKTOP_VERSION
Refresh-ProcessPath

$rdctlCommand = Get-Command rdctl.exe -ErrorAction SilentlyContinue
$rdctlPath = if ($rdctlCommand) { $rdctlCommand.Source } else { $null }
if (-not $rdctlPath) {
    $candidate = Join-Path $env:ProgramFiles 'Rancher Desktop\resources\resources\win32\bin\rdctl.exe'
    if (Test-Path -LiteralPath $candidate -PathType Leaf) { $rdctlPath = $candidate }
}
if (-not $rdctlPath) { throw 'Rancher Desktop installed but rdctl.exe was not found.' }

$settings = Get-RancherSettings -RdctlPath $rdctlPath
if ($settings) {
    Write-Info 'Rancher Desktop already running'
    if (-not (Test-RancherBaseline -Settings $settings)) {
        Write-Info 'Applying Rancher Desktop Moby/Kubernetes baseline'
        $setResult = Invoke-ProbeWithTimeout -FilePath $rdctlPath -ArgumentList @('set','--application.updater.enabled=false','--container-engine.name=moby','--kubernetes-enabled=false') -TimeoutSeconds 90
        Assert-ProbeSucceeded -Result $setResult -Description 'Rancher Desktop settings update'
        $settings = Wait-RancherSettings -RdctlPath $rdctlPath -Deadline ((Get-Date).AddMinutes(3))
    }
}
else {
    Assert-NoCompetingDockerDesktopRuntime

    $startArgs = @(
        'start',
        '--no-modal-dialogs',
        '--application.start-in-background=true',
        '--application.updater.enabled=false',
        '--container-engine.name=moby',
        '--kubernetes.enabled=false'
    )

    Write-Info 'Starting Rancher Desktop in background'
    $overallDeadline = (Get-Date).AddMinutes(5)
    $startResult = Invoke-ProbeWithTimeout -FilePath $rdctlPath -ArgumentList $startArgs -TimeoutSeconds 90
    if (-not $startResult.TimedOut -and $startResult.ExitCode -ne 0) {
        $detail = $startResult.Output -join [Environment]::NewLine
        $diagnostics = Get-RancherFailureDiagnostics
        throw "Rancher Desktop start failed with exit code $($startResult.ExitCode).`n$detail`n$diagnostics"
    }
    if ($startResult.TimedOut) {
        Write-Info 'rdctl start is still initializing; continuing with bounded readiness checks'
    }

    $settings = Wait-RancherSettings -RdctlPath $rdctlPath -Deadline $overallDeadline
}

if (-not $settings) {
    $diagnostics = Get-RancherFailureDiagnostics
    throw "Rancher Desktop did not become ready within 5 minutes.`n$diagnostics"
}

if (-not (Test-RancherBaseline -Settings $settings)) {
    throw 'Rancher Desktop became reachable but the required Moby/Kubernetes-disabled baseline was not applied.'
}

$rdBin = Join-Path $HOME '.rd\bin'
if (Test-Path -LiteralPath $rdBin -PathType Container) {
    Add-UserPathEntry -Path $rdBin -Prepend
    $currentEntries = @($env:Path -split ';' | Where-Object { $_ -and $_ -ne $rdBin })
    $env:Path = (@($rdBin) + $currentEntries) -join ';'
}

$dockerPath = Get-RancherDockerPath

$currentContextResult = Invoke-ProbeWithTimeout -FilePath $dockerPath -ArgumentList @('context','show') -TimeoutSeconds 10
Assert-ProbeSucceeded -Result $currentContextResult -Description 'Docker context query'
$currentContext = if ($currentContextResult.Output.Count -gt 0) { $currentContextResult.Output[0].Trim() } else { '' }
if ($currentContext -ne 'default') {
    Write-Info "Switching Docker context from '$currentContext' to 'default'"
    $contextUseResult = Invoke-ProbeWithTimeout -FilePath $dockerPath -ArgumentList @('context','use','default') -TimeoutSeconds 15
    Assert-ProbeSucceeded -Result $contextUseResult -Description 'Docker context switch'
}

$deadline = (Get-Date).AddMinutes(5)
$dockerReady = $false
$attempt = 0
do {
    $attempt++
    $dockerInfo = Invoke-ProbeWithTimeout -FilePath $dockerPath -ArgumentList @('info') -TimeoutSeconds 10
    if (-not $dockerInfo.TimedOut -and $dockerInfo.ExitCode -eq 0) {
        $dockerReady = $true
        break
    }
    if (($attempt % 2) -eq 0) { Write-Info 'Waiting for Rancher Desktop Moby engine...' }
    Start-Sleep -Seconds 3
} while ((Get-Date) -lt $deadline)

if (-not $dockerReady) {
    $diagnostics = Get-RancherFailureDiagnostics
    throw "Rancher Desktop Moby engine did not become ready within 5 minutes.`n$diagnostics"
}

$dockerVersion = Invoke-ProbeWithTimeout -FilePath $dockerPath -ArgumentList @('--version') -TimeoutSeconds 15
Assert-ProbeSucceeded -Result $dockerVersion -Description 'Docker version check'
$composeVersion = Invoke-ProbeWithTimeout -FilePath $dockerPath -ArgumentList @('compose','version') -TimeoutSeconds 15
Assert-ProbeSucceeded -Result $composeVersion -Description 'Docker Compose version check'
Write-Success 'Rancher Desktop / Moby runtime validated'
