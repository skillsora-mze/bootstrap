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
if ((Get-BootstrapVersion -ConfigPath $config) -ne '1.5.0') { throw 'Unexpected bootstrap version' }
$enabled = @(Get-EnabledModules -ConfigPath $config)
if (($enabled -join ',') -ne ($modules -join ',')) { throw "Unexpected module order: $($enabled -join ',')" }

$packages = Import-PowerShellDataFile (Join-Path $RootDir 'packages/windows/packages.psd1')
if ($packages.SystemPackages.Count -lt 5) { throw 'Windows package manifest unexpectedly small' }

$bootstrap = Get-Content -Raw (Join-Path $RootDir 'bootstrap.ps1')
if ($bootstrap -notmatch 'Assert-WslReady') { throw 'Windows bootstrap must fail fast on missing WSL2 when containers are enabled' }
if ($bootstrap -notmatch 'Select-ModulesInteractive' -or $bootstrap -notmatch 'NonInteractive') { throw 'Interactive/non-interactive module selection missing' }

$windowsLib = Get-Content -Raw (Join-Path $RootDir 'scripts/lib/windows.ps1')
if ($windowsLib -notmatch 'Invoke-NativeCommand') { throw 'Native command wrapper missing' }
if ($windowsLib -notmatch 'build -lt 22631') { throw 'Windows 11 23H2 baseline missing' }
if ($windowsLib -notmatch 'Publish-WingetPortableCommand' -or $windowsLib -notmatch 'Get-ManagedBinDir') { throw 'Deterministic managed WinGet command resolution missing' }

$containerModule = Get-Content -Raw (Join-Path $RootDir 'scripts/modules/containers/install.ps1')

if ($containerModule -notmatch "DistroName = 'Debian'") { throw 'Debian WSL baseline missing' }
if ($containerModule -notmatch 'Assert-WslReady') { throw 'WSL2 preflight missing' }
if ($containerModule -notmatch '--install.*-d.*--no-launch') { throw 'Debian WSL install automation missing' }
if ($containerModule -notmatch '--set-version.*2') { throw 'Debian must be normalized to WSL2' }
if ($containerModule -notmatch 'download\.docker\.com/linux/debian') { throw 'Docker official Debian repository missing' }

foreach ($package in @('docker-ce','docker-ce-cli','containerd.io','docker-buildx-plugin','docker-compose-plugin')) {
    if ($containerModule -notmatch [regex]::Escape($package)) { throw "Docker Engine package missing: $package" }
}

if ($containerModule -notmatch 'systemd=true') { throw 'WSL systemd configuration missing' }
if ($containerModule -notmatch 'systemctl.*enable.*--now.*docker') { throw 'Docker service enable/start logic missing' }
if ($containerModule -notmatch 'docker.*info') { throw 'Docker readiness validation missing' }
if ($containerModule -match 'Rancher|rdctl|SUSE\.RancherDesktop') { throw 'Legacy Rancher Desktop logic remains' }

$awsModule = Get-Content -Raw (Join-Path $RootDir 'scripts/modules/aws/install.ps1')
if ($awsModule -match 'sam\.exe' -or $awsModule -notmatch "Assert-Command -Name 'sam'") { throw 'AWS SAM command resolution is not portable' }

$azureModule = Get-Content -Raw (Join-Path $RootDir 'scripts/modules/azure/install.ps1')
if ($azureModule -notmatch "Install-WingetPackage -Id 'Microsoft.Azd'" -or $azureModule -match "Microsoft\.Azd'.*-Version") { throw 'Microsoft.Azd must use the stable WinGet channel; package and product versions differ' }

$hashicorpModule = Get-Content -Raw (Join-Path $RootDir 'scripts/modules/hashicorp/install.ps1')
if ($hashicorpModule -cnotmatch "Install-WingetPackage -Id 'Hashicorp.Vagrant'") { throw 'Canonical WinGet Vagrant package id missing' }
if ($hashicorpModule -cmatch "HashiCorp\.Vagrant") { throw 'Incorrect WinGet Vagrant package-id casing present' }

$kubeModule = Get-Content -Raw (Join-Path $RootDir 'scripts/modules/kubernetes/install.ps1')
if ($kubeModule -notmatch 'get.helm.sh' -or $kubeModule -notmatch 'Install-VerifiedZipTool') { throw 'Pinned Helm 3 checksum installation missing' }
if ($kubeModule -notmatch 'managedHelm' -or $kubeModule -notmatch 'Replacing stale managed Helm binary') { throw 'Managed Helm version drift recovery missing' }
foreach ($id in @('Kubernetes.kubectl','Kubernetes.kind','Derailed.k9s','ahmetb.kubectx')) {
    if ($kubeModule -notmatch [regex]::Escape("Publish-WingetPortableCommand -Id '$id'")) { throw "Managed portable command publication missing for $id" }
}

$terminalModule = Get-Content -Raw (Join-Path $RootDir 'scripts/modules/terminal/install.ps1')
if ($terminalModule -notmatch 'WindowsPowerShell/profile.ps1' -or $terminalModule -notmatch 'PowerShell/profile.ps1') { throw 'Both Windows PowerShell and PowerShell 7 profiles must be configured' }
if ($terminalModule -notmatch '\[regex\]::IsMatch' -or $terminalModule -notmatch 'RegexOptions\]::Singleline') { throw 'PowerShell managed profile block must use multiline-safe idempotence matching' }

$managedProfile = Get-Content -Raw (Join-Path $RootDir 'scripts/modules/terminal/files/Microsoft.PowerShell_profile.ps1')
if ($managedProfile -notmatch '\.workstation-bootstrap\\bin' -or $managedProfile -notmatch '\$env:Path') { throw 'Managed Windows tool path must be prioritized in PowerShell profiles' }

Write-Host 'Windows static tests passed'
