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
if ($bootstrap -notmatch 'Get-WindowsLocalContainerCapability' -or $bootstrap -notmatch 'Assert-WslReady') { throw 'Windows bootstrap capability-aware WSL gate missing' }
if ($bootstrap -notmatch 'Select-ModulesInteractive' -or $bootstrap -notmatch 'NonInteractive') { throw 'Interactive/non-interactive module selection missing' }

$windowsLib = Get-Content -Raw (Join-Path $RootDir 'scripts/lib/windows.ps1')
if ($windowsLib -notmatch 'Invoke-NativeCommand') { throw 'Native command wrapper missing' }
if ($windowsLib -notmatch 'build -lt 22631') { throw 'Windows 11 23H2 baseline missing' }
if ($windowsLib -notmatch 'Get-WindowsOsArchitecture' -or $windowsLib -notmatch "'AMD64','ARM64'") { throw 'Windows OS architecture support missing' }
if ($windowsLib -notmatch 'Get-WindowsLocalContainerCapability' -or $windowsLib -notmatch 'VMware') { throw 'Windows ARM64 VMware capability gate missing' }
if ($windowsLib -notmatch '0x8a15000f' -or $windowsLib -notmatch 'source.msix') { throw 'Targeted WinGet source repair missing' }
if ($windowsLib -notmatch 'Publish-WingetPortableCommand' -or $windowsLib -notmatch 'Get-ManagedBinDir') { throw 'Deterministic managed WinGet command resolution missing' }
if ($windowsLib -notmatch 'UTF8Encoding' -or $windowsLib -notmatch 'chcp.com 65001') { throw 'Windows UTF-8 console normalization missing' }

$containerModule = Get-Content -Raw (Join-Path $RootDir 'scripts/modules/containers/install.ps1')
if ($containerModule -notmatch 'Docker\.DockerDesktop') { throw 'Docker Desktop WinGet baseline missing' }
if ($containerModule -notmatch '--accept-license' -or $containerModule -notmatch '--backend=wsl-2' -or $containerModule -notmatch '--user') { throw 'Docker Desktop unattended WSL2 installation flags missing' }
if ($containerModule -match '--no-windows-containers') { throw 'Undocumented Docker Desktop installer flag must not be used' }
if ($containerModule -notmatch 'Get-WindowsLocalContainerCapability' -or $containerModule -notmatch 'Containers module skipped') { throw 'Container capability skip missing' }
if ($containerModule -notmatch "desktop','start','--timeout','180") { throw 'Bounded Docker Desktop CLI startup missing' }
if ($containerModule -notmatch "'info','--format','\{\{\.OSType\}\}'") { throw 'Linux container engine validation missing' }
if ($containerModule -notmatch "'compose','version'") { throw 'Docker Compose validation missing' }
if ($containerModule -notmatch "'run','--rm','hello-world'") { throw 'Docker hello-world smoke test missing' }
if ($containerModule -notmatch 'Get-DockerDesktopDiagnostics' -or $containerModule -notmatch "'wsl\.exe'") { throw 'Docker Desktop/WSL diagnostics missing' }
if ($containerModule -notmatch 'Invoke-ProbeWithTimeout' -or $containerModule -notmatch 'WaitForExit') { throw 'Bounded native readiness probe missing from Windows container module' }

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
if ($kubeModule -notmatch 'Get-WindowsOsArchitecture' -or $kubeModule -notmatch "'ARM64' \{ 'arm64' \}" -or $kubeModule -notmatch 'windows-\$helmPlatform') { throw 'Architecture-aware Windows Helm installation missing' }
foreach ($id in @('Kubernetes.kubectl','Derailed.k9s','ahmetb.kubectx')) {
    if ($kubeModule -notmatch [regex]::Escape("Publish-WingetPortableCommand -Id '$id'")) { throw "Managed portable command publication missing for $id" }
}
if ($kubeModule -notmatch 'Get-WindowsLocalContainerCapability' -or $kubeModule -notmatch 'Skipping kind') { throw 'Profile-aware kind skip missing' }

$terminalModule = Get-Content -Raw (Join-Path $RootDir 'scripts/modules/terminal/install.ps1')
if ($terminalModule -notmatch 'WindowsPowerShell/profile.ps1' -or $terminalModule -notmatch 'PowerShell/profile.ps1') { throw 'Both Windows PowerShell and PowerShell 7 profiles must be configured' }
if ($terminalModule -notmatch '\[regex\]::IsMatch' -or $terminalModule -notmatch 'RegexOptions\]::Singleline') { throw 'PowerShell managed profile block must use multiline-safe idempotence matching' }

$managedProfile = Get-Content -Raw (Join-Path $RootDir 'scripts/modules/terminal/files/Microsoft.PowerShell_profile.ps1')
if ($managedProfile -notmatch '\.workstation-bootstrap\\bin' -or $managedProfile -notmatch '\$env:Path') { throw 'Managed Windows tool path must be prioritized in PowerShell profiles' }

Write-Host 'Windows static tests passed'
