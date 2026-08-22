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

### 1. Install Git

#### macOS

```bash
xcode-select --install
git --version
```

#### Debian / Linux

```bash
sudo apt-get update
sudo apt-get install -y git
git --version
```

#### Windows

Open PowerShell:

```powershell
winget install --id Git.Git --exact --source winget --accept-package-agreements --accept-source-agreements
git --version
```

### 2. Clone the repository

macOS / Linux:

```bash
git clone https://github.com/skillsora-mze/bootstrap.git
cd bootstrap
```

Windows:

```powershell
git clone https://github.com/skillsora-mze/bootstrap.git
cd bootstrap
```

### 3. Run the bootstrap

macOS / Debian:

```bash
./bootstrap.sh
```

Windows:

```powershell
.\bootstrap.cmd
```

### 4. Verify the workstation

macOS / Debian:

```bash
./scripts/verify-workstation.sh
```

Windows:

```powershell
.\scripts\verify-workstation.ps1
```

For idempotence testing, run the bootstrap a second time and repeat the workstation verification.

## Design

- modular and idempotent
- configuration-driven module defaults
- no credentials in the repository
- safe platform capability gates
- first-party/signed package sources where practical
- real runtime smoke tests for local container profiles

See `USERGUIDE.md`, `PROJECT_OVERVIEW.md`, `CURRENT_STATE.md`, and `PROJECT_DECISIONS.md` for the operational contract.
