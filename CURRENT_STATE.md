# Current State

Current release candidate: **v1.4.0**.

## Implemented

- Native entry points for macOS/Debian (`bootstrap.sh`) and Windows (`bootstrap.ps1`).
- macOS 14+ Apple Silicon with OrbStack.
- Debian 12 amd64/arm64 with Docker Engine.
- Windows 11 24H2+ x64 with WinGet and Rancher Desktop/Moby; WSL2 preflight occurs before package changes.
- Platform-neutral module layout with Bash and PowerShell implementations.
- Signed APT repositories for Docker, Microsoft Azure CLI, HashiCorp and Kubernetes.
- No direct `curl | bash` pipelines in project code.
- Pinned Kubernetes training baseline in `config/versions.env`.
- Helm 3 baseline preserved across platforms; macOS uses `helm@3` rather than the current Helm 4 default formula.
- Idempotent shell and PowerShell profile integration.
- Bash, macOS static and Windows PowerShell CI jobs.
- Runtime verification scripts for Unix and Windows.

## Windows capability note

AWS, Azure, HashiCorp CLIs, Kubernetes tools and container workflows are native Windows commands. Rancher Desktop uses WSL2 internally. Ansible is intentionally not installed as a native Windows control node; use WSL2 for Ansible-specific labs.

## Validation status

Static validation is automated. **v1.4.0 is not production-validated until real-host smoke tests and second-run idempotence tests pass on macOS Apple Silicon, Debian 12 and Windows 11 x64.**

## Known residual risks

- Homebrew and WinGet packages can evolve outside the repository when a package is not explicitly version-pinned.
- AWS CLI v2 Linux follows the official AWS current installer endpoint; SAM CLI is pinned and SHA-256 verified.
- Some Linux Kubernetes release binaries remain version-pinned without repository-stored hashes; Helm is SHA-256 verified.
- GUI/runtime startup (OrbStack and Rancher Desktop) cannot be fully proven by static CI.
