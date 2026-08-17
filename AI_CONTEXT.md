# AI Context

This file is a source of truth for automated assistants working on Workstation Bootstrap.

## Mission

Provide a simple, modular, idempotent and configuration-driven workstation bootstrap for instructor-led cloud, DevOps and Kubernetes training.

## Supported platforms

- macOS 14+ on Apple Silicon (arm64), using OrbStack as the container runtime.
- Debian 12 on amd64 or arm64, using Docker Engine from Docker's official APT repository.
- Windows 11 24H2+ (build 26100+) on x64, using Rancher Desktop with Moby (`dockerd`). WSL2 is a prerequisite for the runtime, but the bootstrap itself runs natively in PowerShell.

Other platforms are unsupported until they have an implementation and validation coverage.

## Architecture rules

- `bootstrap.sh` is the entry point for macOS and Debian.
- `bootstrap.ps1` is the native Windows entry point.
- Feature selection is controlled by `config/bootstrap.yaml`.
- Toolchain baseline values live in `config/versions.env`.
- Modules live under `scripts/modules/<name>/install.sh` and/or `install.ps1`.
- Bash modules run in isolated subshells; PowerShell modules run as scripts with strict error handling.
- Modules must be safe to run repeatedly.
- Prefer signed vendor repositories and package managers over remote install scripts.
- Never embed credentials, tokens or private keys.
- Do not add a platform to the support matrix until all enabled modules have an explicit behavior on it.

## Container policy

- macOS: OrbStack only. Do not add Docker Desktop.
- Debian: Docker Engine CE from Docker's official repository.
- Windows: Rancher Desktop with Moby and Rancher Desktop Kubernetes disabled. WSL2 is required by Rancher Desktop.
- The Docker-compatible CLI remains required because Compose and kind use the Docker API.

## Windows policy

- Windows bootstrap is native PowerShell, not Git Bash and not a bootstrap executed inside WSL.
- Windows ARM64 is out of scope for v1.4.0.
- Ansible is not installed as a native Windows control node; use WSL2 for Ansible-specific labs.

## Change policy

Use feature branches. Before merge: run platform static checks, update documentation and CHANGELOG, then validate the full bootstrap and a second idempotence run on each supported platform.
