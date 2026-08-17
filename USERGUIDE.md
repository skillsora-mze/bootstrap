# Workstation Bootstrap User Guide

## Requirements

### macOS

- macOS 14+
- Apple Silicon
- Internet access
- administrator privileges

OrbStack is installed automatically through Homebrew. Docker Desktop is not used.

### Debian

- Debian 12
- amd64 or arm64
- Internet access
- `sudo` privileges

### Windows

- Windows 11 24H2 or newer, build 26100+
- x64/amd64
- Internet access
- WinGet available
- WSL2 enabled and initialized for the Rancher Desktop runtime

The bootstrap runs in native PowerShell; it is not executed inside WSL.

## Installation

### macOS / Debian

```bash
git clone https://github.com/ibmmo/workstation-bootstrap.git
cd workstation-bootstrap
./bootstrap.sh
```

### Windows

Open PowerShell:

```powershell
git clone https://github.com/ibmmo/workstation-bootstrap.git
Set-Location workstation-bootstrap
.\\bootstrap.ps1
```

If WSL2 is missing, the Windows bootstrap stops before package installation. Enable it from an elevated PowerShell with:

```powershell
wsl --install --no-distribution
```

Reboot only if Windows requests it, then rerun the bootstrap.

## Post-installation

Open a new terminal session, then verify.

macOS / Debian:

```bash
./scripts/verify-workstation.sh
```

Windows:

```powershell
.\\scripts\\verify-workstation.ps1
```

## Container runtime

### macOS

```bash
orb status
docker info
docker compose version
```

### Debian

```bash
systemctl status docker --no-pager
docker info
```

### Windows

```powershell
rdctl info
docker info
docker compose version
```

Rancher Desktop is configured with Moby (`dockerd`) and its embedded Kubernetes cluster disabled. `kind` is the local Kubernetes lab mechanism.

## Windows Ansible note

Ansible control-node execution is not supported natively by this project on Windows. Use the installed WSL2 environment for Ansible-specific labs.

## Troubleshooting

Keep the exact error output and rerun the bootstrap after correcting the cause. Do not remove vendor repositories, runtimes or profiles manually unless the rollback guide explicitly calls for it.
