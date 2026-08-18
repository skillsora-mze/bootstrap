[CmdletBinding()]
param([Parameter(Mandatory)][string]$RootDir)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $RootDir 'scripts/lib/windows.ps1')

$versions = Get-VersionConfig -Path (Join-Path $RootDir 'config/versions.env')

Install-WingetPackage -Id 'Kubernetes.kubectl' -Version $versions.KUBERNETES_PATCH
$kindVersion = $versions.KIND_VERSION.TrimStart('v')
$k9sVersion = $versions.K9S_VERSION.TrimStart('v')
$kubectxVersion = $versions.KUBECTX_VERSION.TrimStart('v')

Install-WingetPackage -Id 'Kubernetes.kind' -Version $kindVersion
Install-WingetPackage -Id 'Derailed.k9s' -Version $k9sVersion
Install-WingetPackage -Id 'ahmetb.kubectx' -Version $kubectxVersion

# WinGet tracks Helm 4; install the pinned Helm 3 release archive instead.
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

foreach ($cmd in @('kubectl','helm','kind','k9s','kubectx')) { Assert-Command -Name $cmd }

$kubectlResult = Invoke-NativeCommand -FilePath 'kubectl' -ArgumentList @('version','--client','--output=json') -Quiet
$kubectlClient = (($kubectlResult.Output -join [Environment]::NewLine) | ConvertFrom-Json).clientVersion.gitVersion
if ($kubectlClient -ne "v$($versions.KUBERNETES_PATCH)") {
    throw "kubectl version mismatch: expected v$($versions.KUBERNETES_PATCH), got $kubectlClient"
}

$helmResult = Invoke-NativeCommand -FilePath 'helm' -ArgumentList @('version','--short') -Quiet
$helmActual = ($helmResult.Output -join '').Trim()
if (-not $helmActual.StartsWith($helmVersion)) {
    throw "Helm version mismatch: expected $helmVersion, got $helmActual"
}

Invoke-NativeCommand -FilePath 'kind' -ArgumentList @('version') | Out-Null
Invoke-NativeCommand -FilePath 'k9s' -ArgumentList @('version') | Out-Null
Invoke-NativeCommand -FilePath 'kubectx' -ArgumentList @('--help') -Quiet | Out-Null
Write-Success 'Kubernetes tooling validated'
