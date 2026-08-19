[CmdletBinding()]
param([Parameter(Mandatory)][string]$RootDir)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $RootDir 'scripts/lib/windows.ps1')

$source = Join-Path $RootDir 'scripts/modules/terminal/files/Microsoft.PowerShell_profile.ps1'
$managedDir = Join-Path $HOME '.workstation-bootstrap'
$managedProfile = Join-Path $managedDir 'Microsoft.PowerShell_profile.ps1'
New-Item -ItemType Directory -Force -Path $managedDir | Out-Null
Copy-Item -LiteralPath $source -Destination $managedProfile -Force

$markerStart = '# >>> Workstation Bootstrap >>>'
$markerEnd = '# <<< Workstation Bootstrap <<<'
$block = @"
$markerStart
. '$managedProfile'
$markerEnd
"@

function Set-ManagedProfileBlock {
    param([Parameter(Mandatory)][string]$ProfilePath)
    $profileDir = Split-Path -Parent $ProfilePath
    New-Item -ItemType Directory -Force -Path $profileDir | Out-Null
    $current = if (Test-Path $ProfilePath) { Get-Content -Raw $ProfilePath } else { '' }
    $pattern = [regex]::Escape($markerStart) + '.*?' + [regex]::Escape($markerEnd)
    $regexOptions = [Text.RegularExpressions.RegexOptions]::Singleline
    if ([regex]::IsMatch($current, $pattern, $regexOptions)) {
        $updated = [regex]::Replace($current, $pattern, $block, $regexOptions)
        Set-Content -Path $ProfilePath -Value $updated -Encoding utf8
    }
    else {
        Add-Content -Path $ProfilePath -Value "`n$block" -Encoding utf8
    }
    Write-Success "PowerShell profile configured: $ProfilePath"
}

$documents = [Environment]::GetFolderPath('MyDocuments')
$profilePaths = @(
    (Join-Path $documents 'WindowsPowerShell/profile.ps1'),
    (Join-Path $documents 'PowerShell/profile.ps1')
) | Select-Object -Unique

foreach ($profilePath in $profilePaths) {
    Set-ManagedProfileBlock -ProfilePath $profilePath
}
