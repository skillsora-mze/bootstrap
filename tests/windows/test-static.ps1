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
if ($containerModule -notmatch 'SUSE.RancherDesktop' -or $containerModule -notmatch 'container-engine.name=moby') { throw 'Rancher Desktop Moby baseline missing' }
if ($containerModule -notmatch 'application.start-in-background=true') { throw 'Headless Rancher Desktop first-run configuration missing' }
if ($containerModule -notmatch '--no-modal-dialogs') { throw 'Rancher Desktop automation must suppress modal dialogs' }
if ($containerModule -match 'application.path-management-strategy') { throw 'Unsupported Rancher Desktop Windows PATH-management flag present' }
if ($containerModule -notmatch "context','use','default") { throw 'Docker default-context recovery missing' }
if ($containerModule -notmatch 'Invoke-ProbeWithTimeout' -or $containerModule -notmatch 'WaitForExit') { throw 'Bounded native readiness probe missing from Windows container module' }
if ($containerModule -notmatch 'Invoke-ProbeWithTimeout -FilePath \$RdctlPath -ArgumentList @\(''list-settings''\)') { throw 'Rancher Desktop readiness must use a bounded rdctl probe' }
if ($containerModule -notmatch 'Assert-NoCompetingDockerDesktopRuntime') { throw 'Concurrent Docker Desktop runtime preflight missing' }
if ($containerModule -notmatch 'Get-RancherDockerPath' -or $containerModule -notmatch '-FilePath \$dockerPath') { throw 'Rancher Desktop docker.exe must be resolved explicitly' }
if ($containerModule -notmatch 'Get-RancherFailureDiagnostics' -or $containerModule -notmatch 'background\.log') { throw 'Rancher Desktop startup failure diagnostics missing' }
if ($containerModule -match 'Start-Process -FilePath \$rdctlPath') { throw 'rdctl start must not be detached because startup errors would be lost' }
if ($containerModule -notmatch 'Test-RancherBaseline') { throw 'Rancher Desktop settings must be checked before applying a restart-inducing update' }

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
if ($managedProfile -notmatch '\.workstation-bootstrap\\bin' -or $managedProfile -notmatch '\.rd\\bin' -or $managedProfile -notmatch '\$env:Path') { throw 'Managed Windows and Rancher Desktop tool paths must be prioritized in PowerShell profiles' }

Write-Host 'Windows static tests passed'
