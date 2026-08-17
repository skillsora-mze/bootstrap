Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$RootDir = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
. (Join-Path $RootDir 'scripts/lib/windows.ps1')

$modules = @('system_packages','containers','aws','azure','hashicorp','kubernetes','terminal')
foreach ($module in $modules) {
    $path = Join-Path $RootDir "scripts/modules/$module/install.ps1"
    if (-not (Test-Path $path)) { throw "Missing Windows module: $module" }
}
$config = Join-Path $RootDir 'config/bootstrap.yaml'
if ((Get-BootstrapVersion -ConfigPath $config) -ne '1.4.0') { throw 'Unexpected bootstrap version' }
$enabled = @(Get-EnabledModules -ConfigPath $config)
if (($enabled -join ',') -ne ($modules -join ',')) { throw "Unexpected module order: $($enabled -join ',')" }
$packages = Import-PowerShellDataFile (Join-Path $RootDir 'packages/windows/packages.psd1')
if ($packages.SystemPackages.Count -lt 5) { throw 'Windows package manifest unexpectedly small' }
$bootstrap = Get-Content -Raw (Join-Path $RootDir 'bootstrap.ps1')
if ($bootstrap -notmatch 'Assert-WslReady') { throw 'Windows bootstrap must fail fast on missing WSL2 when containers are enabled' }
$containerModule = Get-Content -Raw (Join-Path $RootDir 'scripts/modules/containers/install.ps1')
if ($containerModule -notmatch 'SUSE.RancherDesktop' -or $containerModule -notmatch 'container-engine.name=moby') { throw 'Rancher Desktop Moby baseline missing' }
$kubeModule = Get-Content -Raw (Join-Path $RootDir 'scripts/modules/kubernetes/install.ps1')
if ($kubeModule -notmatch 'get.helm.sh' -or $kubeModule -notmatch 'Install-VerifiedZipTool') { throw 'Pinned Helm 3 checksum installation missing' }
Write-Host 'Windows static tests passed'
