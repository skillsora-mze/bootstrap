# Current State

## Version

`1.5.0` release candidate, final Windows container baseline.

## Implemented

- macOS Apple Silicon with OrbStack.
- Debian 12 amd64/arm64 with Docker Engine CE.
- Windows 11 23H2+ x64 with Docker Desktop/WSL2 and Linux containers.
- Windows 11 ARM64 native CLI support with architecture-aware packages and Helm artifacts.
- Windows ARM64 VMware Fusion guests are detected as client-tools-only: local Docker Desktop startup and local `kind` are skipped rather than allowed to fail.
- Interactive module selection on Bash and PowerShell, with non-interactive CI mode.
- A Windows `bootstrap.cmd` wrapper uses a process-scoped execution-policy bypass and does not change persistent machine/user policy.
- Windows PowerShell console encoding is normalized to UTF-8 to prevent WinGet Unicode progress-bar mojibake.
- WinGet source corruption code `0x8a15000f` is repaired automatically by registering the Microsoft WinGet source package and refreshing sources.
- Windows native-command wrapper treats exit codes as authoritative and prevents harmless stderr warnings from aborting the bootstrap.
- Docker Desktop installation uses WinGet with the WSL2 backend and accepted license, then bounded CLI startup and readiness checks.
- Docker Desktop runtime validation requires the Linux container engine, Docker Compose, and a successful `hello-world` smoke test.
- AWS SAM command resolution uses `sam` rather than a Windows-only executable-name assumption.
- Both Windows PowerShell 5.1 and PowerShell 7 profile locations are configured idempotently, with project-managed tools prioritized.
- WinGet version enforcement for pinned packages automatically upgrades older versions and intentionally blocks automatic downgrades.
- WinGet portable Kubernetes commands are published to the project-managed bin directory to prevent bundled copies from shadowing the selected baseline.
- Helm 3 baseline is preserved across platforms and resolves the Windows amd64/arm64 archive explicitly.
- AWS SAM clean macOS installs use the AWS first-party package installer; Debian installs remain pinned and checksum-verified.
- Debian `azd` uses pinned release artifacts with SHA-256 verification rather than a mutable installer script.
- Direct Linux Helm, kind and k9s release artifacts are checksum-verified with upstream SHA-256 metadata.
- Stable package-manager channels are validated for the configured compatibility contract rather than falsely treated as exact direct-artifact pins.
- CI jobs cover Bash, macOS and Windows static validation.

## Validation status

Static validation is automated. Real-host testing on Windows 11 ARM64 under VMware Fusion on Apple Silicon confirmed that Docker Desktop cannot start because nested virtualization is not exposed. That environment is therefore an explicit client-tools-only profile rather than a failed container target.

Docker Desktop remains the Windows local-container baseline only on Windows systems where hardware virtualization is exposed to the guest/host as required by WSL2.

**v1.5.0 is production-ready only after the applicable smoke-test and second-run idempotence checks in `docs/RELEASE_CHECKLIST.md` pass for the profile being released.**

## Residual risks

- Docker Desktop Windows ARM remains vendor-described as Early Access and is accepted only on environments meeting Docker's virtualization requirements.
- Package-manager tools without explicit version pins follow their vendor/package-manager stable channels.
- AWS CLI v2 Linux uses AWS's current official installer endpoint; its archive is not repository-pinned by SHA-256.
- Homebrew bootstrap uses Homebrew's official current installer rather than a repository-pinned installer revision.
- GUI/runtime behavior such as OrbStack and Docker Desktop startup cannot be fully proven by static CI.
- Existing macOS Homebrew installations of `aws-sam-cli` are accepted with a warning; clean installs use AWS's first-party package.
