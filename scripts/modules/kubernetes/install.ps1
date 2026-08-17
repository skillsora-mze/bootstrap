[CmdletBinding()]
param([Parameter(Mandatory)][string]$RootDir)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $RootDir 'scripts/lib/windows.ps1')

$versions = Get-VersionConfig -Path (Join-Path $RootDir 'config/versions.env')

# WinGet has the pinned kubectl and kind releases; keep those package-managed.
Install-WingetPackage -Id 'Kubernetes.kubectl' -Version $versions.KUBERNETES_PATCH
Install-WingetPackage -Id 'Kubernetes.kind' -Version $versions.KIND_VERSION.TrimStart('v')
Install-WingetPackage -Id 'Derailed.k9s' -Version $versions.K9S_VERSION.TrimStart('v')
Install-WingetPackage -Id 'ahmetb.kubectx' -Version $versions.KUBECTX_VERSION.TrimStart('v')

# Current WinGet Helm package tracks Helm 4; install the pinned Helm 3 archive instead.
$helmVersion = $versions.HELM_VERSION
$helmArchive = "helm-$helmVersion-windows-amd64.zip"
$helmArgs = @{
    Name = 'Helm'
    Uri = "https://get.helm.sh/$helmArchive"
    ChecksumUri = "https://get.helm.sh/$helmArchive.sha256sum"
    ArchiveRelativePath = 'windows-amd64/helm.exe'
    DestinationFile = 'helm.exe'
}
Install-VerifiedZipTool @helmArgs | Out-Null

foreach ($cmd in @('kubectl.exe','helm.exe','kind.exe','k9s.exe','kubectx.exe')) { Assert-Command -Name $cmd }

$kubectlClient = (& kubectl.exe version --client --output=json | ConvertFrom-Json).clientVersion.gitVersion
if ($kubectlClient -ne "v$($versions.KUBERNETES_PATCH)") {
    throw "kubectl version mismatch: expected v$($versions.KUBERNETES_PATCH), got $kubectlClient"
}
$helmActual = (& helm.exe version --short).Trim()
if (-not $helmActual.StartsWith($helmVersion)) { throw "Helm version mismatch: expected $helmVersion, got $helmActual" }

& kind.exe version
& k9s.exe version
& kubectx.exe --help *> $null
Write-Success 'Kubernetes tooling validated'
