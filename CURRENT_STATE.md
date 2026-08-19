# Current State

## Version

`1.5.0` release candidate.

## Implemented

- macOS Apple Silicon with OrbStack.
- Debian 12 amd64/arm64 with Docker Engine CE.
- Windows 11 23H2+ x64 with Rancher Desktop/Moby and WSL2 preflight.
- Interactive module selection on Bash and PowerShell, with non-interactive CI mode.
- macOS module selection has real package ownership: the base Brewfile contains system tools only, while containers, cloud, HashiCorp and Kubernetes packages are installed by their respective modules.
- Windows native-command wrapper treats exit codes as authoritative and prevents harmless stderr warnings from aborting the bootstrap.
- Rancher Desktop startup uses bounded automation with modal dialogs disabled, Moby enforcement, embedded Kubernetes disabled, competing Docker Desktop runtime detection, explicit Rancher Docker command resolution and failure diagnostics.
- Stale Docker Desktop context recovery normalizes Docker to `default` after Rancher Desktop is ready.
- AWS SAM command resolution uses `sam` rather than the incorrect Windows-only assumption `sam.exe`.
- Both Windows PowerShell 5.1 and PowerShell 7 profile locations are configured idempotently, with project-managed tools and Rancher Desktop CLI paths prioritized.
- WinGet version enforcement for pinned packages automatically upgrades older versions and intentionally blocks automatic downgrades.
- WinGet portable Kubernetes commands are published to the project-managed bin directory to prevent bundled Docker/Rancher copies from shadowing the selected baseline.
- Helm 3 baseline is preserved across platforms.
- AWS SAM clean macOS installs use the AWS first-party package installer; Debian installs remain pinned and checksum-verified.
- Debian `azd` uses pinned release artifacts with SHA-256 verification rather than a mutable installer script.
- Direct Linux Helm, kind and k9s release artifacts are checksum-verified with upstream SHA-256 metadata.
- Stable package-manager channels are validated for the configured compatibility contract rather than falsely treated as exact direct-artifact pins.
- CI jobs cover Bash, macOS and Windows; Windows CI parses scripts with Windows PowerShell 5.1 and runs PSScriptAnalyzer under PowerShell 7.

## Validation status

Static validation is automated. Windows runtime testing has exposed and driven fixes for Rancher Desktop startup/error handling, competing runtime detection, stale Docker contexts, native stderr handling and command shadowing.

**v1.5.0 is not production-validated until the complete smoke-test matrix and second-run idempotence checks in `docs/RELEASE_CHECKLIST.md` pass.**

## Residual risks

- Package-manager tools without explicit version pins follow their vendor/package-manager stable channels.
- AWS CLI v2 Linux uses AWS's current official installer endpoint; its archive is not repository-pinned by SHA-256.
- Homebrew bootstrap uses Homebrew's official current installer rather than a repository-pinned installer revision.
- GUI/runtime behavior such as OrbStack and Rancher Desktop startup cannot be fully proven by static CI.
- Existing macOS Homebrew installations of `aws-sam-cli` are accepted with a warning; clean installs use AWS's first-party package.
