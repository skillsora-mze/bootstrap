Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Info([string]$Message) { Write-Host "[INFO] $Message" }
function Write-Success([string]$Message) { Write-Host "[ OK ] $Message" }
function Write-Warn([string]$Message) { Write-Warning $Message }
function Write-Section([string]$Message) { Write-Host "`n=== $Message ===" }

function Get-ManagedBinDir {
    return (Join-Path $HOME '.workstation-bootstrap/bin')
}

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

function Get-KnownModules {
    return @('system_packages','containers','aws','azure','hashicorp','kubernetes','terminal')
}

function Get-EnabledModules {
    param([Parameter(Mandatory)][string]$ConfigPath)
    $content = Get-Content -LiteralPath $ConfigPath
    foreach ($module in (Get-KnownModules)) {
        if ($content -match "^\s{2}$([regex]::Escape($module)):\s*true\s*$") { $module }
    }
}

function Select-ModulesInteractive {
    param([Parameter(Mandatory)][string[]]$DefaultModules)

    $known = @(Get-KnownModules)
    $selected = @{}
    foreach ($module in $known) { $selected[$module] = ($DefaultModules -contains $module) }

    while ($true) {
        Write-Section 'Module selection'
        for ($i = 0; $i -lt $known.Count; $i++) {
            $module = $known[$i]
            $mark = if ($selected[$module]) { 'x' } else { ' ' }
            Write-Host ("{0}. [{1}] {2}" -f ($i + 1), $mark, $module)
        }
        Write-Host ''
        $answer = Read-Host 'Toggle module number(s), comma-separated; Enter to continue'
        if ([string]::IsNullOrWhiteSpace($answer)) { break }

        foreach ($token in ($answer -split '[,\s]+' | Where-Object { $_ })) {
            $number = 0
            if (-not [int]::TryParse($token, [ref]$number) -or $number -lt 1 -or $number -gt $known.Count) {
                Write-Warn "Ignoring invalid module selection: $token"
                continue
            }
            $module = $known[$number - 1]
            $selected[$module] = -not $selected[$module]
        }
    }

    return @($known | Where-Object { $selected[$_] })
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
    $managedBin = Get-ManagedBinDir
    if (Test-Path -LiteralPath $managedBin -PathType Container) {
        $env:Path = @($managedBin, $machine, $user) -join ';'
    }
    else {
        $env:Path = @($machine, $user) -join ';'
    }
}

function Invoke-NativeCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$FilePath,
        [string[]]$ArgumentList = @(),
        [switch]$AllowFailure,
        [switch]$Quiet
    )

    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = @(& $FilePath @ArgumentList 2>&1)
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previous
    }

    if (-not $Quiet) {
        foreach ($line in $output) { Write-Host $line.ToString() }
    }

    if ($exitCode -ne 0 -and -not $AllowFailure) {
        $detail = ($output | ForEach-Object { $_.ToString() }) -join [Environment]::NewLine
        throw "Native command failed ($exitCode): $FilePath $($ArgumentList -join ' ')`n$detail"
    }

    return [pscustomobject]@{
        ExitCode = $exitCode
        Output = @($output | ForEach-Object { $_.ToString() })
    }
}

function Get-WingetInstalledVersion {
    param([Parameter(Mandatory)][string]$Id)
    $result = Invoke-NativeCommand -FilePath 'winget.exe' -ArgumentList @('list','--id',$Id,'--exact','--source','winget','--accept-source-agreements','--disable-interactivity') -AllowFailure -Quiet
    if ($result.ExitCode -ne 0) { return $null }
    foreach ($line in $result.Output) {
        if ($line -match ([regex]::Escape($Id) + '\s+([0-9][0-9A-Za-z._+-]*)')) {
            return $Matches[1]
        }
    }
    return ''
}

function Test-WingetPackageInstalled {
    param([Parameter(Mandatory)][string]$Id)
    return ($null -ne (Get-WingetInstalledVersion -Id $Id))
}

function Install-WingetPackage {
    param(
        [Parameter(Mandatory)][string]$Id,
        [string]$Version
    )

    $installedVersion = Get-WingetInstalledVersion -Id $Id
    if ($null -ne $installedVersion) {
        if (-not $Version -or $installedVersion -eq $Version) {
            $suffix = if ($installedVersion) { " ($installedVersion)" } else { '' }
            Write-Info "$Id already installed$suffix"
            return
        }

        try {
            $installed = [version]$installedVersion
            $target = [version]$Version
        }
        catch {
            throw "$Id is installed at version '$installedVersion', but baseline '$Version' is required. Update it explicitly, then rerun."
        }

        if ($installed -eq $target) {
            Write-Info "$Id already installed ($installedVersion)"
            return
        }
        if ($installed -gt $target) {
            throw "$Id version $installedVersion is newer than pinned baseline $Version. Automatic downgrade is intentionally disabled."
        }

        Write-Info "Upgrading $Id from $installedVersion to $Version"
        Invoke-NativeCommand -FilePath 'winget.exe' -ArgumentList @('upgrade','--id',$Id,'--exact','--source','winget','--version',$Version,'--accept-package-agreements','--accept-source-agreements','--disable-interactivity') | Out-Null
        Refresh-ProcessPath
        return
    }

    Write-Info "Installing $Id"
    $args = @('install','--id',$Id,'--exact','--source','winget','--accept-package-agreements','--accept-source-agreements','--disable-interactivity')
    if ($Version) { $args += @('--version', $Version) }
    Invoke-NativeCommand -FilePath 'winget.exe' -ArgumentList $args | Out-Null
    Refresh-ProcessPath
}

function Publish-WingetPortableCommand {
    param(
        [Parameter(Mandatory)][string]$Id,
        [Parameter(Mandatory)][string]$Command
    )

    $packageRoot = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages'
    if (-not (Test-Path -LiteralPath $packageRoot -PathType Container)) {
        throw "WinGet package directory not found: $packageRoot"
    }

    $packageDirs = @(Get-ChildItem -LiteralPath $packageRoot -Directory -ErrorAction Stop | Where-Object { $_.Name -like "$Id`_*" })
    $candidates = @()
    foreach ($dir in $packageDirs) {
        $candidates += @(Get-ChildItem -LiteralPath $dir.FullName -Recurse -File -Filter "$Command.exe" -ErrorAction SilentlyContinue)
    }
    $source = $candidates | Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 1
    if (-not $source) {
        throw "WinGet portable command not found for $Id: $Command.exe"
    }

    $managedBin = Get-ManagedBinDir
    New-Item -ItemType Directory -Force -Path $managedBin | Out-Null
    $destination = Join-Path $managedBin "$Command.exe"
    Copy-Item -LiteralPath $source.FullName -Destination $destination -Force
    Add-UserPathEntry -Path $managedBin -Prepend
    Refresh-ProcessPath
    Write-Info "Managed $Command from $Id -> $destination"
    return $destination
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
    $result = Invoke-NativeCommand -FilePath 'wsl.exe' -ArgumentList @('--status') -AllowFailure -Quiet
    return ($result.ExitCode -eq 0)
}

function Assert-WslReady {
    if (-not (Test-WslReady)) {
        throw 'WSL2 is required by the Windows container runtime. Run "wsl --install --no-distribution" from an elevated PowerShell, reboot if requested, then rerun bootstrap.ps1.'
    }
}

function Add-UserPathEntry {
    param(
        [Parameter(Mandatory)][string]$Path,
        [switch]$Prepend
    )
    $current = [Environment]::GetEnvironmentVariable('Path', 'User')
    $entries = @($current -split ';' | Where-Object { $_ -and $_ -ne $Path })
    $newEntries = if ($Prepend) { @($Path) + $entries } else { $entries + @($Path) }
    $newValue = $newEntries -join ';'
    if ($newValue -ne $current) {
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
    $binDir = Get-ManagedBinDir
    New-Item -ItemType Directory -Force -Path $binDir | Out-Null
    $destination = Join-Path $binDir $DestinationFile
    if (Test-Path -LiteralPath $destination) {
        Write-Info "$Name already installed at $destination"
        Add-UserPathEntry -Path $binDir -Prepend
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
        Add-UserPathEntry -Path $binDir -Prepend
        return $destination
    }
    finally {
        Remove-Item -LiteralPath $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
