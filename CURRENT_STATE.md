# Current State

## Version

`1.5.0` release candidate.

## Implemented

- macOS Apple Silicon with OrbStack.
- Debian 12 amd64/arm64 with Docker Engine CE.
- Windows 11 23H2+ x64 with Rancher Desktop/Moby and WSL2 preflight.
- Interactive module selection on Bash and PowerShell, with non-interactive CI mode.
- Windows native-command wrapper that treats exit codes as authoritative and prevents harmless stderr warnings from aborting the bootstrap.
- Rancher Desktop first-run startup in background, Moby enforcement, embedded Kubernetes disabled, and stale Docker Desktop context recovery to `default`.
- AWS SAM command resolution using `sam` rather than the incorrect Windows-only assumption `sam.exe`.
- Both Windows PowerShell 5.1 and PowerShell 7 profile locations configured idempotently.
- WinGet version enforcement for pinned packages: automatic upgrade to the requested version; automatic downgrade intentionally blocked.
- Helm 3 baseline preserved across platforms.
- AWS SAM clean macOS installs use the AWS first-party package installer; Debian installs remain pinned and checksum-verified.
- Debian `azd` uses pinned release artifacts with SHA-256 verification rather than a mutable installer script.
- CI jobs for Bash, macOS and Windows; Windows CI parses scripts with Windows PowerShell 5.1 and runs PSScriptAnalyzer under PowerShell 7.

## Validation status

Static validation is automated. Windows runtime testing has already exposed and driven fixes for Rancher Desktop first-run behavior, stale Docker contexts and native stderr handling.

**v1.5.0 is not production-validated until the complete smoke-test matrix and second-run idempotence checks in `docs/RELEASE_CHECKLIST.md` pass.**

## Residual risks

- Package-manager tools without explicit version pins follow their vendor/package-manager stable channels.
- AWS CLI v2 Linux uses AWS's current official installer endpoint; its archive is not repository-pinned by SHA-256.
- GUI/runtime behavior such as OrbStack and Rancher Desktop startup cannot be fully proven by static CI.
- Existing macOS Homebrew installations of `aws-sam-cli` are accepted with a warning; clean installs use AWS's first-party package.
