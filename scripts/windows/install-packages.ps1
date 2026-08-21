[CmdletBinding()]
param([Parameter(Mandatory)][string]$RootDir)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $RootDir 'scripts/lib/windows.ps1')

function Install-PowerShellArm64 {
    param([Parameter(Mandatory)][hashtable]$Versions)

    $version = $Versions['POWERSHELL_VERSION']
    $expectedSha256 = $Versions['POWERSHELL_SHA256_ARM64']

    if (-not $version) {
        throw 'POWERSHELL_VERSION is missing from config/versions.env'
    }
    if (-not $expectedSha256) {
        throw 'POWERSHELL_SHA256_ARM64 is missing from config/versions.env'
    }

    Refresh-ProcessPath

    if (Get-Command pwsh.exe -ErrorAction SilentlyContinue) {
        Write-Info 'PowerShell already installed'
        return
    }

    $uri = "https://github.com/PowerShell/PowerShell/releases/download/v$version/PowerShell-$version-win-arm64.msi"
    $msi = Join-Path $env:TEMP "PowerShell-$version-win-arm64.msi"

    Write-Info "Installing PowerShell $version ARM64 from official MSI"

    try {
        Invoke-WebRequest `
            -Uri $uri `
            -OutFile $msi `
            -UseBasicParsing

        $actualSha256 = (Get-FileHash -LiteralPath $msi -Algorithm SHA256).Hash

        if ($actualSha256 -ne $expectedSha256) {
            throw "PowerShell MSI SHA256 mismatch. Expected $expectedSha256, got $actualSha256"
        }

        Write-Info 'PowerShell ARM64 MSI checksum validated'

        $process = Start-Process `
            -FilePath 'msiexec.exe' `
            -ArgumentList @(
                '/i',
                "`"$msi`"",
                '/qn',
                '/norestart'
            ) `
            -Wait `
            -PassThru

        if ($process.ExitCode -notin @(0, 3010)) {
            throw "PowerShell ARM64 MSI installation failed with exit code $($process.ExitCode)"
        }
    }
    finally {
        Remove-Item -LiteralPath $msi -Force -ErrorAction SilentlyContinue
    }

    Refresh-ProcessPath
    Assert-Command -Name 'pwsh'
}

$manifest = Import-PowerShellDataFile (
    Join-Path $RootDir 'packages/windows/packages.psd1'
)

$versions = Get-VersionConfig -Path (
    Join-Path $RootDir 'config/versions.env'
)

foreach ($package in $manifest.SystemPackages) {
    if (
        $package.Id -eq 'Microsoft.PowerShell' -and
        (Get-WindowsOsArchitecture) -eq 'ARM64'
    ) {
        Install-PowerShellArm64 -Versions $versions
        continue
    }

    Install-WingetPackage -Id $package.Id
}

foreach ($package in $manifest.SystemPackages) {
    Assert-Command -Name $package.Command
}

Write-Success 'Windows system packages validated'
