[CmdletBinding()]
param([Parameter(Mandatory)][string]$RootDir)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $RootDir 'scripts/lib/windows.ps1')

$versions = Get-VersionConfig -Path (Join-Path $RootDir 'config/versions.env')
$containerCapability = Get-WindowsLocalContainerCapability

Install-WingetPackage -Id 'Kubernetes.kubectl' -Version $versions.KUBERNETES_PATCH
$kindVersion = $versions.KIND_VERSION.TrimStart('v')
$k9sVersion = $versions.K9S_VERSION.TrimStart('v')
$kubectxVersion = $versions.KUBECTX_VERSION.TrimStart('v')

if ($containerCapability.Supported) {
    Install-WingetPackage -Id 'Kubernetes.kind' -Version $kindVersion
}
else {
    Write-Warn "Skipping kind: $($containerCapability.Reason)"
}
Install-WingetPackage -Id 'Derailed.k9s' -Version $k9sVersion
Install-WingetPackage -Id 'ahmetb.kubectx' -Version $kubectxVersion

# Publish validated package-manager binaries into the project-managed bin directory.
$kubectlPath = Publish-WingetPortableCommand -Id 'Kubernetes.kubectl' -Command 'kubectl'
$kindPath = $null
if ($containerCapability.Supported) {
    $kindPath = Publish-WingetPortableCommand -Id 'Kubernetes.kind' -Command 'kind'
}
$k9sPath = Publish-WingetPortableCommand -Id 'Derailed.k9s' -Command 'k9s'
$kubectxPath = Publish-WingetPortableCommand -Id 'ahmetb.kubectx' -Command 'kubectx'

# WinGet tracks Helm 4; install the pinned Helm 3 release archive instead.
$helmVersion = $versions.HELM_VERSION
$windowsOsArch = Get-WindowsOsArchitecture
$helmPlatform = switch ($windowsOsArch) {
    'AMD64' { 'amd64' }
    'ARM64' { 'arm64' }
    default { throw "Unsupported Windows architecture for Helm: $windowsOsArch" }
}
$helmArchive = "helm-$helmVersion-windows-$helmPlatform.zip"
$managedHelm = Join-Path $HOME '.workstation-bootstrap/bin/helm.exe'
if (Test-Path -LiteralPath $managedHelm -PathType Leaf) {
    $managedHelmResult = Invoke-NativeCommand -FilePath $managedHelm -ArgumentList @('version','--short') -AllowFailure -Quiet
    $managedHelmVersion = ($managedHelmResult.Output -join '').Trim()
    if ($managedHelmResult.ExitCode -ne 0 -or -not $managedHelmVersion.StartsWith($helmVersion)) {
        Write-Info "Replacing stale managed Helm binary ($managedHelmVersion)"
        Remove-Item -LiteralPath $managedHelm -Force
    }
}
$helmArgs = @{
    Name = 'Helm'
    Uri = "https://get.helm.sh/$helmArchive"
    ChecksumUri = "https://get.helm.sh/$helmArchive.sha256sum"
    ArchiveRelativePath = "windows-$helmPlatform/helm.exe"
    DestinationFile = 'helm.exe'
}
$helmPath = Install-VerifiedZipTool @helmArgs

$requiredCommands = @('kubectl','helm','k9s','kubectx')
if ($containerCapability.Supported) { $requiredCommands += 'kind' }
foreach ($cmd in $requiredCommands) { Assert-Command -Name $cmd }

$kubectlResult = Invoke-NativeCommand -FilePath $kubectlPath -ArgumentList @('version','--client','--output=json') -Quiet
$kubectlClient = (($kubectlResult.Output -join [Environment]::NewLine) | ConvertFrom-Json).clientVersion.gitVersion
if ($kubectlClient -ne "v$($versions.KUBERNETES_PATCH)") {
    throw "kubectl version mismatch: expected v$($versions.KUBERNETES_PATCH), got $kubectlClient"
}

$helmResult = Invoke-NativeCommand -FilePath $helmPath -ArgumentList @('version','--short') -Quiet
$helmActual = ($helmResult.Output -join '').Trim()
if (-not $helmActual.StartsWith($helmVersion)) {
    throw "Helm version mismatch: expected $helmVersion, got $helmActual"
}

if ($containerCapability.Supported) {
    Invoke-NativeCommand -FilePath $kindPath -ArgumentList @('version') | Out-Null
}
Invoke-NativeCommand -FilePath $k9sPath -ArgumentList @('version') | Out-Null
Invoke-NativeCommand -FilePath $kubectxPath -ArgumentList @('--help') -Quiet | Out-Null
Write-Success 'Kubernetes tooling validated'
