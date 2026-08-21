# Project Overview

Workstation Bootstrap prepares standardized training workstations for AWS, Microsoft Azure, Infrastructure as Code, Kubernetes and container labs.

## Goals

1. Native entry points for Unix-like systems and Windows.
2. Interactive module selection for instructors and students without changing repository configuration.
3. Repeatable execution without duplicate shell/profile content or stale temporary files.
4. Explicit support matrix rather than best-effort platform detection.
5. Predictable toolchain baselines for lab reproducibility.
6. No credentials or environment-specific secrets in the repository.
7. Graceful degradation when a host cannot provide local virtualization.

## Supported matrix

| Platform | Architecture | Package manager | Container capability |
|---|---|---|---|
| macOS 14+ | arm64 | Homebrew + vendor installers | OrbStack |
| Debian 12 | amd64 / arm64 | APT + verified vendor releases | Docker Engine CE |
| Windows 11 23H2+ | amd64/x64 | WinGet + verified vendor releases | Docker Desktop + WSL2 |
| Windows 11 23H2+ | arm64 | WinGet + verified vendor releases | Docker Desktop + WSL2 when virtualization is available |
| Windows 11 ARM64 on VMware Fusion / Apple Silicon | arm64 | WinGet + verified vendor releases | No local container runtime; client-tools-only profile |

Windows cloud, IaC and Kubernetes client CLIs run natively in PowerShell. Windows ARM64 VMware Fusion guests are detected and do not attempt Docker Desktop or local `kind`, because the required nested virtualization is unavailable in that environment.

## Modules

| Module | Purpose |
|---|---|
| `system_packages` | Base OS packages/tools |
| `containers` | OrbStack, Docker Engine or Docker Desktop/WSL2; safely skipped on unsupported Windows virtualization profiles |
| `aws` | AWS CLI v2 and AWS SAM CLI |
| `azure` | Azure CLI and Azure Developer CLI (`azd`) |
| `hashicorp` | Terraform, Packer, Vagrant; Ansible where natively supported |
| `kubernetes` | kubectl, Helm 3, k9s, kubectx and `kind` where a local container runtime is supported |
| `terminal` | Training aliases and shell/PowerShell integration |

## Non-goals

- production server hardening
- production Kubernetes cluster provisioning
- credential provisioning
- Red Hat-family distributions or Intel Macs
- forcing nested virtualization where the host hypervisor does not provide it
- native Windows Ansible control-node support
