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
    if (Test-Path -LiteralPath $candidate -PathType Leaf) { $rdctlPath = $candidate }
}
if (-not $rdctlPath) { throw 'Rancher Desktop installed but rdctl.exe was not found.' }

# Start rdctl asynchronously so a first-run initialization cannot block bootstrap.ps1.
$startArgs = @(
    'start',
    '--application.start-in-background=true',
    '--application.path-management-strategy=manual',
    '--application.updater.enabled=false',
    '--container-engine.name=moby',
    '--kubernetes.enabled=false'
)
Write-Info 'Starting Rancher Desktop in background'
Start-Process -FilePath $rdctlPath -ArgumentList $startArgs -WindowStyle Hidden | Out-Null

$deadline = (Get-Date).AddMinutes(5)
$settings = $null
do {
    $result = Invoke-NativeCommand -FilePath $rdctlPath -ArgumentList @('list-settings') -AllowFailure -Quiet
    if ($result.ExitCode -eq 0 -and $result.Output.Count -gt 0) {
        try {
            $settings = (($result.Output -join [Environment]::NewLine) | ConvertFrom-Json)
        }
        catch {
            $settings = $null
        }
    }
    if ($settings) { break }
    Start-Sleep -Seconds 3
} while ((Get-Date) -lt $deadline)

if (-not $settings) {
    throw 'Rancher Desktop did not become ready within 5 minutes.'
}

# Enforce the training baseline even if Rancher Desktop was previously configured.
Invoke-NativeCommand -FilePath $rdctlPath -ArgumentList @('set','--application.path-management-strategy=manual','--application.updater.enabled=false','--container-engine.name=moby','--kubernetes-enabled=false') -Quiet | Out-Null

# Rancher Desktop keeps its CLI utilities in ~/.rd/bin when PATH management is manual.
$rdBin = Join-Path $HOME '.rd\bin'
if (Test-Path -LiteralPath $rdBin -PathType Container) {
    Add-UserPathEntry -Path $rdBin
}

Refresh-ProcessPath
Assert-Command -Name 'docker'

$currentContextResult = Invoke-NativeCommand -FilePath 'docker' -ArgumentList @('context','show') -AllowFailure -Quiet
$currentContext = if ($currentContextResult.Output.Count -gt 0) { $currentContextResult.Output[0].Trim() } else { '' }
if ($currentContext -ne 'default') {
    Write-Info "Switching Docker context from '$currentContext' to 'default'"
    Invoke-NativeCommand -FilePath 'docker' -ArgumentList @('context','use','default') -Quiet | Out-Null
}

$deadline = (Get-Date).AddMinutes(5)
$dockerReady = $false
do {
    $dockerInfo = Invoke-NativeCommand -FilePath 'docker' -ArgumentList @('info') -AllowFailure -Quiet
    if ($dockerInfo.ExitCode -eq 0) {
        $dockerReady = $true
        break
    }
    Start-Sleep -Seconds 3
} while ((Get-Date) -lt $deadline)

if (-not $dockerReady) {
    throw 'Rancher Desktop Moby engine did not become ready within 5 minutes.'
}

Invoke-NativeCommand -FilePath 'docker' -ArgumentList @('--version') | Out-Null
Invoke-NativeCommand -FilePath 'docker' -ArgumentList @('compose','version') | Out-Null
Write-Success 'Rancher Desktop / Moby runtime validated'
