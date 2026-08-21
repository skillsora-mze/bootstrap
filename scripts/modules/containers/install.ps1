[CmdletBinding()]
param([Parameter(Mandatory)][string]$RootDir)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $RootDir 'scripts/lib/windows.ps1')

$containerCapability = Get-WindowsLocalContainerCapability
if (-not $containerCapability.Supported) {
    Write-Warn $containerCapability.Reason
    Write-Success 'Containers module skipped for this Windows profile'
    return
}

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

function Assert-ProbeSucceeded {
    param(
        [Parameter(Mandatory)]$Result,
        [Parameter(Mandatory)][string]$Description
    )

    $detail = $Result.Output -join [Environment]::NewLine
    if ($Result.TimedOut) { throw "$Description timed out.`n$detail" }
    if ($Result.ExitCode -ne 0) { throw "$Description failed with exit code $($Result.ExitCode).`n$detail" }
}

function Get-DockerCliPath {
    Refresh-ProcessPath
    $command = Get-Command docker.exe -ErrorAction SilentlyContinue
    if ($command) { return $command.Source }

    $candidates = @(
        (Join-Path $env:LOCALAPPDATA 'Programs\DockerDesktop\resources\bin\docker.exe'),
        (Join-Path $env:LOCALAPPDATA 'Programs\Docker\Docker\resources\bin\docker.exe'),
        (Join-Path $env:ProgramFiles 'Docker\Docker\resources\bin\docker.exe')
    )
    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) { return $candidate }
    }

    throw 'Docker Desktop is installed but docker.exe could not be resolved. Open a new PowerShell terminal and rerun the bootstrap.'
}

function Install-DockerDesktop {
    $packageId = 'Docker.DockerDesktop'
    if (Test-WingetPackageInstalled -Id $packageId) {
        Write-Info 'Docker Desktop already installed'
        return
    }

    Write-Info 'Installing Docker Desktop with WSL2 backend'
    $override = 'install --quiet --accept-license --backend=wsl-2 --user'
    Invoke-NativeCommand -FilePath 'winget.exe' -ArgumentList @(
        'install','--id',$packageId,'--exact','--source','winget',
        '--accept-package-agreements','--accept-source-agreements','--disable-interactivity',
        '--override',$override
    ) | Out-Null
    Refresh-ProcessPath
}

function Get-DockerDesktopDiagnostics {
    param([Parameter(Mandatory)][string]$DockerPath)

    $lines = @()
    $status = Invoke-ProbeWithTimeout -FilePath $DockerPath -ArgumentList @('desktop','status') -TimeoutSeconds 15
    if ($status.Output.Count -gt 0) {
        $lines += 'Docker Desktop status:'
        $lines += $status.Output
    }

    $wsl = Invoke-ProbeWithTimeout -FilePath 'wsl.exe' -ArgumentList @('--list','--verbose') -TimeoutSeconds 15
    if ($wsl.Output.Count -gt 0) {
        $lines += 'WSL distributions:'
        $lines += $wsl.Output
    }

    return ($lines -join [Environment]::NewLine)
}

Write-Info 'Configuring Docker Desktop with WSL2 backend'
Assert-WslReady
Install-DockerDesktop

$dockerPath = Get-DockerCliPath
$dockerBin = Split-Path -Parent $dockerPath
Add-UserPathEntry -Path $dockerBin -Prepend
Refresh-ProcessPath

$status = Invoke-ProbeWithTimeout -FilePath $dockerPath -ArgumentList @('desktop','status') -TimeoutSeconds 15
if ($status.ExitCode -ne 0 -or (($status.Output -join ' ') -notmatch '(?i)running')) {
    Write-Info 'Starting Docker Desktop'
    $start = Invoke-ProbeWithTimeout -FilePath $dockerPath -ArgumentList @('desktop','start','--timeout','180') -TimeoutSeconds 210
    if ($start.ExitCode -ne 0 -or $start.TimedOut) {
        $diagnostics = Get-DockerDesktopDiagnostics -DockerPath $dockerPath
        $detail = $start.Output -join [Environment]::NewLine
        throw "Docker Desktop failed to start.`n$detail`n$diagnostics"
    }
}
else {
    Write-Info 'Docker Desktop already running'
}

$deadline = (Get-Date).AddMinutes(3)
$dockerReady = $false
$attempt = 0
do {
    $attempt++
    $dockerInfo = Invoke-ProbeWithTimeout -FilePath $dockerPath -ArgumentList @('info','--format','{{.OSType}}') -TimeoutSeconds 15
    if (-not $dockerInfo.TimedOut -and $dockerInfo.ExitCode -eq 0) {
        $osType = ($dockerInfo.Output | Select-Object -First 1).Trim()
        if ($osType -ne 'linux') {
            throw "Docker Desktop is running with container OS '$osType'. The training baseline requires Linux containers."
        }
        $dockerReady = $true
        break
    }
    if (($attempt % 2) -eq 0) { Write-Info 'Waiting for Docker Desktop engine...' }
    Start-Sleep -Seconds 3
} while ((Get-Date) -lt $deadline)

if (-not $dockerReady) {
    $diagnostics = Get-DockerDesktopDiagnostics -DockerPath $dockerPath
    throw "Docker Desktop engine did not become ready within 3 minutes.`n$diagnostics"
}

$dockerVersion = Invoke-ProbeWithTimeout -FilePath $dockerPath -ArgumentList @('version') -TimeoutSeconds 30
Assert-ProbeSucceeded -Result $dockerVersion -Description 'Docker version check'

$composeVersion = Invoke-ProbeWithTimeout -FilePath $dockerPath -ArgumentList @('compose','version') -TimeoutSeconds 30
Assert-ProbeSucceeded -Result $composeVersion -Description 'Docker Compose version check'

Write-Info 'Running Docker smoke test (hello-world)'
$helloWorld = Invoke-ProbeWithTimeout -FilePath $dockerPath -ArgumentList @('run','--rm','hello-world') -TimeoutSeconds 120
Assert-ProbeSucceeded -Result $helloWorld -Description 'Docker hello-world smoke test'
if (($helloWorld.Output -join [Environment]::NewLine) -notmatch 'Hello from Docker!') {
    throw 'Docker hello-world completed without the expected success marker.'
}

Write-Success 'Docker Desktop / WSL2 runtime validated'
