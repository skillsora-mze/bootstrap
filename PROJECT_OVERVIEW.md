# Project Overview

Workstation Bootstrap prepares standardized training workstations for AWS, Microsoft Azure, Infrastructure as Code, Kubernetes and container labs.

## Goals

1. One native entry point per OS family: `./bootstrap.sh` on macOS/Linux and `.\bootstrap.ps1` on Windows.
2. Repeatable execution without duplicate shell/profile configuration or stale temporary files.
3. Explicit platform support rather than best-effort detection.
4. Minimal operational complexity for instructors and students.
5. No credentials or environment-specific secrets in the repository.

## Supported matrix

| Platform | Architecture | Package manager | Container runtime |
|---|---|---|---|
| macOS 14+ | arm64 | Homebrew | OrbStack |
| Debian 12 | amd64 / arm64 | APT | Docker Engine CE |
| Windows 11 24H2+ | amd64/x64 | WinGet | Rancher Desktop + Moby |

Windows requires WSL2 for Rancher Desktop. The bootstrap and cloud/Kubernetes CLIs run natively in PowerShell.

## Enabled modules

| Module | Purpose |
|---|---|
| `system_packages` | Base OS packages/tools |
| `containers` | OrbStack, Docker Engine or Rancher Desktop/Moby depending on platform |
| `aws` | AWS CLI v2 and AWS SAM CLI |
| `azure` | Azure CLI and Azure Developer CLI (`azd`) |
| `hashicorp` | Terraform, Packer, Vagrant; Ansible where natively supported |
| `kubernetes` | kubectl, Helm 3, kind, k9s and kubectx |
| `terminal` | Training aliases and shell/PowerShell integration |

## Non-goals

- Production server hardening.
- Kubernetes cluster provisioning.
- Credential provisioning.
- Red Hat-family distributions or Intel Macs.
- Windows ARM64 in v1.4.0.
- Native Windows Ansible control-node support.
