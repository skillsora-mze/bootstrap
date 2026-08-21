# Project Decisions

## D001 - OrbStack on macOS
Use OrbStack as the macOS container runtime. Docker Desktop is not the macOS baseline.

## D002 - Explicit support matrix
Support macOS 14+ Apple Silicon, Debian 12 amd64/arm64, and Windows 11 23H2+ x64/arm64 with profile-specific local-container capability.

## D003 - Platform-neutral containers module
Use the `containers` module, implemented with OrbStack, Docker Engine or Docker Desktop/WSL2 according to platform and runtime capability. Unsupported local-virtualization profiles must skip safely rather than fail late.

## D004 - Configuration split
Keep module defaults in `config/bootstrap.yaml` and pinned toolchain versions/hashes in `config/versions.env`.

## D005 - Module isolation
Run Bash modules in subshells and PowerShell modules as strict scripts.

## D006 - Supply-chain preference
Prefer signed repositories and first-party package managers/installers. Version-pin and checksum direct release downloads when upstream publishes hashes. Never pipe network content directly to a shell.

## D007 - Release validation
Static CI is necessary but not sufficient. Releases require first-run and second-run smoke tests for each applicable supported profile.

## D008 - Native Windows entry point
Use native Windows PowerShell tooling rather than Git Bash or running the bootstrap inside WSL. Provide `bootstrap.cmd` as the recommended fresh-VM launcher so script execution does not require a persistent execution-policy change.

## D009 - Docker Desktop on Windows
Use Docker Desktop with the WSL2 Linux-container backend when Windows exposes the required hardware virtualization. Install and start it unattended where practical. Docker Desktop Kubernetes is not required; `kind` provides local Kubernetes labs only when the local container runtime is available.

## D010 - Windows baseline
Support Windows 11 build 22631+ on x64 and arm64 for native workstation tooling. Docker Desktop uses the native installer selected by WinGet; architecture-specific direct artifacts resolve x64/arm64 explicitly.

## D011 - Helm 3 baseline
Standardize on Helm 3.21.4. macOS uses `helm@3`; Windows uses the pinned architecture-specific release archive with SHA-256 verification.

## D012 - Interactive selection
Interactive terminal launches offer module selection by default. Selection applies only to the current run and never rewrites `config/bootstrap.yaml`. CI/unattended runs use explicit non-interactive mode.

## D013 - Native command handling on Windows
Centralize external command execution in `Invoke-NativeCommand`. Native exit codes determine success; informational stderr output must not become a terminating PowerShell error.

## D014 - Safe version enforcement
When a WinGet package has a pinned baseline, upgrade older versions automatically but never downgrade newer versions automatically. Report the mismatch for explicit operator action.

## D015 - PowerShell profile compatibility
Configure both Windows PowerShell 5.1 and PowerShell 7 current-user all-host profiles so a bootstrap started from either shell produces a consistent user environment.

## D016 - Windows ARM64 VMware Fusion profile
Treat Windows 11 ARM64 guests running under VMware Fusion on Apple Silicon as client-tools-only. Broadcom does not expose nested virtualization to these guests, so local Docker Desktop/WSL2 virtualization and local `kind` are not supported. The bootstrap detects this profile, skips the `containers` runtime, and installs Kubernetes client tools without `kind`.

## D017 - WinGet self-repair on fresh Windows profiles
If WinGet exists but its community source fails with source-data-missing error `0x8a15000f`, repair the Microsoft source package and refresh the default sources before package installation. Do not apply the repair for unrelated WinGet/network failures.

## D018 - PowerShell installation on Windows ARM64
On Windows ARM64, install PowerShell from the official architecture-specific MSI rather than the WinGet MSIX bundle. Fresh WinRM-provisioned Windows ARM64 guests can fail to install the WinGet MSIX bundle with `0x80070002` even though an official ARM64 MSI is available. Pin the PowerShell release version and ARM64 MSI SHA-256 in `config/versions.env`, verify the checksum before installation, and keep the existing WinGet path unchanged for other Windows architectures.
