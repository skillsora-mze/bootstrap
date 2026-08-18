# Workstation Bootstrap User Guide

## Requirements

### macOS
- macOS 14+
- Apple Silicon
- Internet access
- administrator privileges

OrbStack is installed through Homebrew. Docker Desktop is not used.

### Debian
- Debian 12
- amd64 or arm64
- Internet access
- `sudo` privileges

### Windows
- Windows 11 23H2 or newer, build 22631+
- x64/amd64
- Internet access
- WinGet
- WSL2 enabled for Rancher Desktop

The bootstrap itself runs in native PowerShell.

## Installation

### macOS / Debian

```bash
git clone https://github.com/skillsora-mze/bootstrap.git
cd bootstrap
./bootstrap.sh
```

### Windows

```powershell
git clone https://github.com/skillsora-mze/bootstrap.git
Set-Location bootstrap
.\bootstrap.ps1
```

If WSL2 is missing, the Windows bootstrap stops before package changes. From an elevated PowerShell:

```powershell
wsl --install --no-distribution
```

Reboot only if Windows requests it.

## Interactive module selection

Interactive runs show all modules with their defaults:

```text
1. [x] system_packages
2. [x] containers
3. [x] aws
4. [x] azure
5. [x] hashicorp
6. [x] kubernetes
7. [x] terminal
```

Enter numbers such as `3,4` to toggle AWS and Azure. Press Enter with no value to start. The choice applies only to that run and does not edit `config/bootstrap.yaml`.

Use `./bootstrap.sh --non-interactive` or `.\bootstrap.ps1 -NonInteractive` for automation.

## Post-installation

Open a new terminal session, then run:

```bash
./scripts/verify-workstation.sh
```

or on Windows:

```powershell
.\scripts\verify-workstation.ps1
```

## Container runtime

macOS: `orb status`, `docker info`, `docker compose version`.

Debian: `systemctl status docker --no-pager`, then `docker info` after re-login if group membership was newly added.

Windows: Rancher Desktop is configured with Moby, embedded Kubernetes disabled, and Docker context `default`. `kind` provides the local Kubernetes cluster mechanism.

## Windows Ansible note

Native Windows Ansible control-node execution is outside this project's support matrix. Use WSL2 for Ansible-specific labs.
