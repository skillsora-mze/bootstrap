# Workstation Bootstrap

Reproducible workstation bootstrap for cloud, DevOps and Kubernetes training labs.

## Supported profiles

| Platform | Architecture | Local containers |
|---|---|---|
| macOS 14+ | arm64 | OrbStack |
| Debian 12 | amd64 / arm64 | Docker Engine CE |
| Windows 11 23H2+ | x64 | Docker Desktop + WSL2 |
| Windows 11 23H2+ | arm64 | Docker Desktop + WSL2 when hardware virtualization is exposed |
| Windows 11 ARM64 on VMware Fusion / Apple Silicon | arm64 | Not available; client-tools-only profile |

Windows ARM64 VMware Fusion guests still receive system, AWS, Azure, HashiCorp, terminal, kubectl, Helm, k9s and kubectx tooling. The bootstrap skips Docker Desktop and `kind` locally on that profile.

## Quick start

macOS / Debian:

```bash
./bootstrap.sh
```

Windows (recommended on a fresh VM):

```powershell
.\bootstrap.cmd
```

Unattended Windows:

```powershell
.\bootstrap.cmd -NonInteractive
```

Direct PowerShell invocation remains available when execution policy permits:

```powershell
.\bootstrap.ps1
```

## Design

- modular and idempotent
- configuration-driven module defaults
- no credentials in the repository
- safe platform capability gates
- first-party/signed package sources where practical
- real runtime smoke tests for local container profiles

See `USERGUIDE.md`, `PROJECT_OVERVIEW.md`, `CURRENT_STATE.md`, and `PROJECT_DECISIONS.md` for the operational contract.
