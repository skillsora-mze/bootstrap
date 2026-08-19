# Project Decisions

## D001 - OrbStack on macOS
Use OrbStack as the macOS container runtime. Docker Desktop is not the baseline.

## D002 - Explicit support matrix
Support macOS 14+ Apple Silicon, Debian 12 amd64/arm64, and Windows 11 23H2+ x64 only.

## D003 - Platform-neutral containers module
Use the `containers` module, implemented with OrbStack, Docker Engine or Rancher Desktop/Moby according to platform.

## D004 - Configuration split
Keep module defaults in `config/bootstrap.yaml` and pinned toolchain versions/hashes in `config/versions.env`.

## D005 - Module isolation
Run Bash modules in subshells and PowerShell modules as strict scripts.

## D006 - Supply-chain preference
Prefer signed repositories and first-party package managers/installers. Version-pin and checksum direct release downloads when upstream publishes hashes. Never pipe network content directly to a shell.

## D007 - Release validation
Static CI is necessary but not sufficient. Releases require first-run and second-run smoke tests on all supported platforms.

## D008 - Native Windows entry point
Use `bootstrap.ps1` and native Windows package tooling rather than Git Bash or running the bootstrap inside WSL.

## D009 - Rancher Desktop on Windows
Use Rancher Desktop with Moby and disable embedded Kubernetes. Start/configure it headlessly when possible. `kind` provides local Kubernetes labs.

## D010 - Windows baseline
Support Windows 11 build 22631+ on x64. Windows ARM64 remains out of scope until every module is validated.

## D011 - Helm 3 baseline
Standardize on Helm 3.21.4. macOS uses `helm@3`; Windows uses the pinned release archive with SHA-256 verification.

## D012 - Interactive selection
Interactive terminal launches offer module selection by default. Selection applies only to the current run and never rewrites `config/bootstrap.yaml`. CI/unattended runs use explicit non-interactive mode.

## D013 - Native command handling on Windows
Centralize external command execution in `Invoke-NativeCommand`. Native exit codes determine success; informational stderr output must not become a terminating PowerShell error.

## D014 - Safe version enforcement
When a WinGet package has a pinned baseline, upgrade older versions automatically but never downgrade newer versions automatically. Report the mismatch for explicit operator action.

## D015 - PowerShell profile compatibility
Configure both Windows PowerShell 5.1 and PowerShell 7 current-user all-host profiles so a bootstrap started from either shell produces a consistent user environment.
