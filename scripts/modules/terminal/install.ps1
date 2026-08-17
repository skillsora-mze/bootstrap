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

$profileDir = Split-Path -Parent $PROFILE.CurrentUserAllHosts
$profilePath = $PROFILE.CurrentUserAllHosts
New-Item -ItemType Directory -Force -Path $profileDir | Out-Null
$markerStart = '# >>> Workstation Bootstrap >>>'
$markerEnd = '# <<< Workstation Bootstrap <<<'
$block = @"
$markerStart
. '$managedProfile'
$markerEnd
"@

$current = if (Test-Path $profilePath) { Get-Content -Raw $profilePath } else { '' }
$pattern = [regex]::Escape($markerStart) + '.*?' + [regex]::Escape($markerEnd)
if ($current -match $pattern) {
    $updated = [regex]::Replace($current, $pattern, $block, [Text.RegularExpressions.RegexOptions]::Singleline)
    Set-Content -Path $profilePath -Value $updated -Encoding utf8
} else {
    Add-Content -Path $profilePath -Value "`n$block" -Encoding utf8
}
Write-Success "PowerShell profile configured: $profilePath"
