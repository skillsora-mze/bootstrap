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

& $rdctlPath start | Out-Null
& $rdctlPath set --container-engine.name=moby --kubernetes-enabled=false | Out-Null

$deadline = (Get-Date).AddMinutes(3)
do {
    Refresh-ProcessPath
    if (Get-Command docker.exe -ErrorAction SilentlyContinue) {
        & docker.exe info *> $null
        if ($LASTEXITCODE -eq 0) { break }
    }
    Start-Sleep -Seconds 3
} while ((Get-Date) -lt $deadline)

Assert-Command -Name 'docker.exe'
& docker.exe info *> $null
if ($LASTEXITCODE -ne 0) { throw 'Rancher Desktop Moby engine did not become ready.' }
& docker.exe --version
& docker.exe compose version
Write-Success 'Rancher Desktop / Moby runtime validated'
