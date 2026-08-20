[CmdletBinding()]
param([Parameter(Mandatory)][string]$RootDir)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $RootDir 'scripts/lib/windows.ps1')

$DistroName = 'Debian'

function Invoke-Wsl {
    param(
        [Parameter(Mandatory)][string[]]$ArgumentList,
        [switch]$AllowFailure,
        [switch]$Quiet
    )

    $args = @('-d', $DistroName) + $ArgumentList
    return Invoke-NativeCommand `
        -FilePath 'wsl.exe' `
        -ArgumentList $args `
        -AllowFailure:$AllowFailure `
        -Quiet:$Quiet
}

function Test-WslDistributionInstalled {
    $result = Invoke-NativeCommand `
        -FilePath 'wsl.exe' `
        -ArgumentList @('--list', '--quiet') `
        -AllowFailure `
        -Quiet

    if ($result.ExitCode -ne 0) {
        return $false
    }

    foreach ($line in $result.Output) {
        if ($line.Trim() -eq $DistroName) {
            return $true
        }
    }

    return $false
}

function Test-WslDistributionVersion2 {
    $result = Invoke-NativeCommand `
        -FilePath 'wsl.exe' `
        -ArgumentList @('--list', '--verbose') `
        -AllowFailure `
        -Quiet

    if ($result.ExitCode -ne 0) {
        return $false
    }

    foreach ($line in $result.Output) {
        if ($line -match 'Debian' -and $line -match '\s2\s*$') {
            return $true
        }
    }

    return $false
}

function Install-DebianWsl {
    Write-Info 'Debian WSL distribution is not installed'
    Write-Info 'Installing Debian for WSL2'

    $result = Invoke-NativeCommand `
        -FilePath 'wsl.exe' `
        -ArgumentList @('--install', '-d', $DistroName, '--no-launch') `
        -AllowFailure

    if ($result.ExitCode -ne 0) {
        throw 'Debian WSL installation failed.'
    }

    throw @'
Debian WSL installation has been requested.

A Windows restart may be required before Debian can start.
Restart Windows if requested, then rerun bootstrap.ps1.

The containers module will continue with Docker Engine installation on the next run.
'@
}

function Install-DockerEngine {
    Write-Info 'Installing Docker Engine CE inside Debian WSL'

    $script = @'
set -eu

if dpkg -s docker-ce >/dev/null 2>&1; then
    echo "[INFO] Docker Engine CE already installed"
    exit 0
fi

for package in docker.io docker-compose docker-doc docker-buildx podman-docker containerd runc; do
    if dpkg -s "$package" >/dev/null 2>&1; then
        echo "[ERROR] Conflicting container package detected: $package"
        exit 20
    fi
done

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y ca-certificates curl

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg \
    -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

. /etc/os-release

cat > /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: ${VERSION_CODENAME}
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

apt-get update

DEBIAN_FRONTEND=noninteractive apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin
'@

    $result = Invoke-Wsl `
        -ArgumentList @(
            '--user', 'root',
            '--',
            'bash', '-lc', $script
        ) `
        -AllowFailure

    if ($result.ExitCode -eq 20) {
        throw 'A conflicting container package is installed inside Debian WSL. Remove it explicitly before rerunning the bootstrap.'
    }

    if ($result.ExitCode -ne 0) {
        throw "Docker Engine installation failed inside Debian WSL with exit code $($result.ExitCode)."
    }
}

function Configure-DockerService {
    Write-Info 'Enabling systemd in Debian WSL'

    $script = @'
set -eu

if [ ! -f /etc/wsl.conf ] || ! grep -Eq '^[[:space:]]*systemd[[:space:]]*=[[:space:]]*true' /etc/wsl.conf; then
    cat > /etc/wsl.conf <<EOF
[boot]
systemd=true
EOF
fi
'@

    Invoke-Wsl `
        -ArgumentList @(
            '--user', 'root',
            '--',
            'bash', '-lc', $script
        ) | Out-Null

    Write-Info 'Restarting Debian WSL to apply systemd configuration'

    Invoke-NativeCommand `
        -FilePath 'wsl.exe' `
        -ArgumentList @('--terminate', $DistroName) `
        -AllowFailure `
        -Quiet | Out-Null

    Start-Sleep -Seconds 2

    $startResult = Invoke-Wsl `
        -ArgumentList @(
            '--user', 'root',
            '--',
            'systemctl', 'enable', '--now', 'docker'
        ) `
        -AllowFailure

    if ($startResult.ExitCode -ne 0) {
        throw 'Docker service could not be started inside Debian WSL.'
    }
}

function Test-DockerEngine {
    Write-Info 'Validating Docker Engine inside Debian WSL'

    $info = Invoke-Wsl `
        -ArgumentList @(
            '--user', 'root',
            '--',
            'docker', 'info'
        ) `
        -AllowFailure `
        -Quiet

    if ($info.ExitCode -ne 0) {
        throw 'Docker Engine is installed but is not reachable inside Debian WSL.'
    }

    Invoke-Wsl `
        -ArgumentList @(
            '--user', 'root',
            '--',
            'docker', '--version'
        ) | Out-Null

    Invoke-Wsl `
        -ArgumentList @(
            '--user', 'root',
            '--',
            'docker', 'compose', 'version'
        ) | Out-Null
}

Write-Info 'Configuring Debian WSL2 with Docker Engine CE'

Assert-WslReady

if (-not (Test-WslDistributionInstalled)) {
    Install-DebianWsl
}

if (-not (Test-WslDistributionVersion2)) {
    Write-Info 'Setting Debian to WSL2'

    Invoke-NativeCommand `
        -FilePath 'wsl.exe' `
        -ArgumentList @('--set-version', $DistroName, '2') | Out-Null
}

Install-DockerEngine
Configure-DockerService
Test-DockerEngine

Write-Success 'Debian WSL2 / Docker Engine CE runtime validated'
