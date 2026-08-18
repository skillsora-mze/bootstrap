# Project Overview

Workstation Bootstrap prepares standardized training workstations for AWS, Microsoft Azure, Infrastructure as Code, Kubernetes and container labs.

## Goals

1. Native entry points for Unix-like systems and Windows.
2. Interactive module selection for instructors and students without changing repository configuration.
3. Repeatable execution without duplicate shell/profile content or stale temporary files.
4. Explicit support matrix rather than best-effort platform detection.
5. Predictable toolchain baselines for lab reproducibility.
6. No credentials or environment-specific secrets in the repository.

## Supported matrix

| Platform | Architecture | Package manager | Container runtime |
|---|---|---|---|
| macOS 14+ | arm64 | Homebrew + vendor installers | OrbStack |
| Debian 12 | amd64 / arm64 | APT + verified vendor releases | Docker Engine CE |
| Windows 11 23H2+ | amd64/x64 | WinGet + verified vendor releases | Rancher Desktop + Moby |

Windows requires WSL2 for Rancher Desktop. The bootstrap and cloud/Kubernetes CLIs run natively in PowerShell.

## Modules

| Module | Purpose |
|---|---|
| `system_packages` | Base OS packages/tools |
| `containers` | OrbStack, Docker Engine or Rancher Desktop/Moby |
| `aws` | AWS CLI v2 and AWS SAM CLI |
| `azure` | Azure CLI and Azure Developer CLI (`azd`) |
| `hashicorp` | Terraform, Packer, Vagrant; Ansible where natively supported |
| `kubernetes` | kubectl, Helm 3, kind, k9s and kubectx |
| `terminal` | Training aliases and shell/PowerShell integration |

## Non-goals

- production server hardening
- Kubernetes cluster provisioning
- credential provisioning
- Red Hat-family distributions or Intel Macs
- Windows ARM64 in v1.5.0
- native Windows Ansible control-node support
