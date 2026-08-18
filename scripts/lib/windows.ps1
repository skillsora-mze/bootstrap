Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Info([string]$Message) { Write-Host "[INFO] $Message" }
function Write-Success([string]$Message) { Write-Host "[ OK ] $Message" }
function Write-Warn([string]$Message) { Write-Warning $Message }
function Write-Section([string]$Message) { Write-Host "`n=== $Message ===" }

function Assert-SupportedWindowsPlatform {
    if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
        throw 'This entry point supports Windows only.'
    }
    if ($env:PROCESSOR_ARCHITECTURE -ne 'AMD64') {
        throw "Supported Windows architecture: x64/amd64 only (detected: $env:PROCESSOR_ARCHITECTURE)."
    }
    $build = [Environment]::OSVersion.Version.Build
    if ($build -lt 22631) {
        throw "Windows 11 23H2 or newer is required (build >= 22631; detected: $build)."
    }
}

function Assert-WinGet {
    if (-not (Get-Command winget.exe -ErrorAction SilentlyContinue)) {
        throw 'WinGet is required. Install/update Microsoft App Installer, then rerun the bootstrap.'
    }
}

function Get-BootstrapVersion {
    param([Parameter(Mandatory)][string]$ConfigPath)
    $line = Select-String -Path $ConfigPath -Pattern '^\s*version:\s*["'']?([^"'']+)["'']?\s*$' | Select-Object -First 1
    if (-not $line) { throw 'bootstrap.version not found in config/bootstrap.yaml' }
    return $line.Matches[0].Groups[1].Value.Trim()
}

function Get-EnabledModules {
    param([Parameter(Mandatory)][string]$ConfigPath)
    $known = @('system_packages','containers','aws','azure','hashicorp','kubernetes','terminal')
    $content = Get-Content -LiteralPath $ConfigPath
    foreach ($module in $known) {
        if ($content -match "^\s{2}$([regex]::Escape($module)):\s*true\s*$") { $module }
    }
}

function Get-VersionConfig {
    param([Parameter(Mandatory)][string]$Path)
    $values = @{}
    foreach ($line in Get-Content -LiteralPath $Path) {
        $trimmed = $line.Trim()
        if (-not $trimmed -or $trimmed.StartsWith('#')) { continue }
        $parts = $trimmed -split '=', 2
        if ($parts.Count -eq 2) { $values[$parts[0].Trim()] = $parts[1].Trim() }
    }
    return $values
}

function Refresh-ProcessPath {
    $machine = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $user = [Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = @($machine, $user) -join ';'
}

function Test-WingetPackageInstalled {
    param([Parameter(Mandatory)][string]$Id)
    & winget.exe list --id $Id --exact --source winget --accept-source-agreements 2>$null | Out-Null
    return ($LASTEXITCODE -eq 0)
}

function Install-WingetPackage {
    param(
        [Parameter(Mandatory)][string]$Id,
        [string]$Version
    )
    if (Test-WingetPackageInstalled -Id $Id) {
        Write-Info "$Id already installed"
        return
    }

    Write-Info "Installing $Id"
    $args = @('install','--id',$Id,'--exact','--source','winget','--accept-package-agreements','--accept-source-agreements','--disable-interactivity')
    if ($Version) { $args += @('--version', $Version) }
    & winget.exe @args
    if ($LASTEXITCODE -ne 0) { throw "WinGet failed for $Id (exit code $LASTEXITCODE)." }
    Refresh-ProcessPath
}

function Assert-Command {
    param([Parameter(Mandatory)][string]$Name)
    Refresh-ProcessPath
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Required command not found after installation: $Name"
    }
}

function Test-WslReady {
    if (-not (Get-Command wsl.exe -ErrorAction SilentlyContinue)) { return $false }
    & wsl.exe --status *> $null
    return ($LASTEXITCODE -eq 0)
}

function Assert-WslReady {
    if (-not (Test-WslReady)) {
        throw 'WSL2 is required by the Windows container runtime. Run "wsl --install --no-distribution" from an elevated PowerShell, reboot if requested, then rerun bootstrap.ps1.'
    }
}

function Add-UserPathEntry {
    param([Parameter(Mandatory)][string]$Path)
    $current = [Environment]::GetEnvironmentVariable('Path', 'User')
    $entries = @($current -split ';' | Where-Object { $_ })
    if ($entries -notcontains $Path) {
        $newValue = (@($entries) + $Path) -join ';'
        [Environment]::SetEnvironmentVariable('Path', $newValue, 'User')
    }
    Refresh-ProcessPath
}

function Install-VerifiedZipTool {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][uri]$Uri,
        [Parameter(Mandatory)][uri]$ChecksumUri,
        [Parameter(Mandatory)][string]$ArchiveRelativePath,
        [Parameter(Mandatory)][string]$DestinationFile
    )
    $binDir = Join-Path $HOME '.workstation-bootstrap/bin'
    New-Item -ItemType Directory -Force -Path $binDir | Out-Null
    $destination = Join-Path $binDir $DestinationFile
    if (Test-Path -LiteralPath $destination) {
        Write-Info "$Name already installed at $destination"
        Add-UserPathEntry -Path $binDir
        return $destination
    }

    $tempDir = Join-Path ([IO.Path]::GetTempPath()) ("workstation-bootstrap-" + [guid]::NewGuid())
    New-Item -ItemType Directory -Path $tempDir | Out-Null
    try {
        $archive = Join-Path $tempDir 'tool.zip'
        $checksumFile = Join-Path $tempDir 'tool.sha256'
        Invoke-WebRequest -UseBasicParsing -Uri $Uri -OutFile $archive
        Invoke-WebRequest -UseBasicParsing -Uri $ChecksumUri -OutFile $checksumFile
        $expected = ((Get-Content -LiteralPath $checksumFile -Raw).Trim() -split '\s+')[0].ToLowerInvariant()
        $actual = (Get-FileHash -Algorithm SHA256 -LiteralPath $archive).Hash.ToLowerInvariant()
        if ($expected -ne $actual) { throw "$Name SHA-256 mismatch." }
        Expand-Archive -LiteralPath $archive -DestinationPath $tempDir -Force
        $source = Join-Path $tempDir $ArchiveRelativePath
        if (-not (Test-Path -LiteralPath $source -PathType Leaf)) { throw "$Name executable not found in archive: $ArchiveRelativePath" }
        Copy-Item -LiteralPath $source -Destination $destination -Force
        Add-UserPathEntry -Path $binDir
        return $destination
    }
    finally {
        Remove-Item -LiteralPath $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
