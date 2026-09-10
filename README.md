# Workstation Bootstrap

Reproducible workstation bootstrap for cloud, DevOps and Kubernetes training labs.

## Supported profiles

| Platform | Architecture | Local containers |
|---|---|---|
| macOS 14+ | arm64 | OrbStack |
| Debian 11, 12, 13+ / Ubuntu | amd64 / arm64 | Docker Engine CE |
| Fedora | amd64 / arm64 | Docker Engine CE |
| openSUSE Leap / Tumbleweed | amd64 / arm64 (Vagrant limitation below) | Distribution Docker |
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

macOS / Linux:

```bash
./bootstrap.sh
```

Windows:

```powershell
.\bootstrap.cmd
```

### 4. Verify the workstation

macOS / Linux:

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

### Linux compatibility

The bootstrap accepts Debian 11 and newer, Ubuntu, and derivatives declaring
`ID_LIKE=debian` or `ID_LIKE=ubuntu` in `/etc/os-release`, plus Fedora
and openSUSE Leap/Tumbleweed. Bash, sudo and the native package manager
(APT, DNF or Zypper) are required; the containers module also requires systemd. Ubuntu repositories must
include universe for the base package list. Arch, Alpine and immutable editions (Fedora Atomic/CoreOS, openSUSE MicroOS)
are not supported.

Docker uses the Debian or Ubuntu repository as appropriate. Ubuntu derivatives
(such as Linux Mint) use `UBUNTU_CODENAME`. If a Debian derivative uses its own
codename, supply the actual base release explicitly, for example:
`LINUX_BASE_CODENAME=trixie ./bootstrap.sh` (only for a Debian 13 base).
Never substitute an unrelated release. Future releases are not blocked by an
upper version limit, but installation still depends on package and vendor
repository availability. Tests cover release detection and package-manager routing. Full installation
on every distribution and architecture has not been verified.

On Fedora, Docker uses its official Fedora repository; on openSUSE it uses
`docker` and `docker-compose` from the distribution. Azure CLI and Ansible use
native packages. On both RPM families, kubectl, kubectx/kubens, Terraform,
Packer and azd use upstream downloads with SHA-256 verification. Vagrant uses
Fedora's package or the official HashiCorp RPM on openSUSE x86_64.
**openSUSE ARM64:** the HashiCorp module requires an existing Vagrant installation;
otherwise deselect that module (no official ARM64 Vagrant RPM is available).
No conflicting container packages are removed automatically.

Install Git before cloning on Fedora with `sudo dnf install -y git`, or on
openSUSE with `sudo zypper --non-interactive install git`. Then run
`./bootstrap.sh` as on Debian.

RPM installation references: [Docker Fedora](https://docs.docker.com/engine/install/fedora/),
[HashiCorp downloads](https://developer.hashicorp.com/terraform/install),
[Azure Developer CLI releases](https://github.com/Azure/azure-dev/releases/tag/azure-dev-cli_1.31.1).

On Linux, an existing stable Azure Developer CLI (`azd`) at version 1.31.1
or newer is accepted and preserved. Clean installations still use the pinned,
SHA-256-verified release. Older versions report the detected version and require
an update; preview or unrecognized version output is rejected.
