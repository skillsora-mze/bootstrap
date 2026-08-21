# User Guide

## Purpose

Workstation Bootstrap prepares training workstations for cloud, Infrastructure as Code, container and Kubernetes labs.

## Supported environments

### macOS

- macOS 14+
- Apple Silicon / arm64
- OrbStack local container runtime

### Debian

- Debian 12
- amd64 or arm64
- Docker Engine CE local container runtime

### Windows

- Windows 11 23H2+ (build 22631+)
- x64/amd64 or arm64
- native PowerShell tooling
- Docker Desktop + WSL2 only when required hardware virtualization is available

### Windows ARM64 on VMware Fusion / Apple Silicon

This is a supported **client-tools-only** profile. VMware Fusion on Apple Silicon does not expose nested virtualization to Windows ARM guests, so the bootstrap does not attempt a local Docker Desktop engine and does not install `kind` for local clusters. Cloud CLIs, Terraform/Packer/Vagrant, kubectl, Helm, k9s, kubectx and terminal tooling remain available.

## Windows first-run prerequisites

Git is needed to clone the public repository. On a fresh Windows image, WinGet may require Microsoft App Installer registration. Once the repository is present, use the wrapper below so no persistent execution-policy change is required:

```powershell
.\bootstrap.cmd
```

For unattended execution:

```powershell
.\bootstrap.cmd -NonInteractive
```

The wrapper applies `ExecutionPolicy Bypass` only to the child PowerShell process.

## WinGet source recovery

The bootstrap validates the WinGet community source. If WinGet returns `0x8a15000f` (source data missing), the bootstrap registers the official Microsoft source package, resets/updates sources and retries. Unrelated failures are not masked.

## Module selection

Default module state is defined in `config/bootstrap.yaml`:

- `system_packages`
- `containers`
- `aws`
- `azure`
- `hashicorp`
- `kubernetes`
- `terminal`

Interactive selection affects only the current run and never rewrites repository configuration.

## Containers

- macOS: OrbStack.
- Debian: Docker Engine CE.
- Windows with virtualization capability: Docker Desktop, WSL2 backend, Linux containers, Docker Compose and `hello-world` smoke test.
- Windows ARM64 VMware Fusion / Apple Silicon: local container runtime skipped by design.

## Kubernetes

`kubectl`, Helm 3, k9s and kubectx are installed on Windows supported profiles. `kind` is installed only when the profile has a supported local container runtime. Docker Desktop Kubernetes is not part of the baseline.

## Verification

Windows:

```powershell
.\scripts\verify-workstation.ps1
```

macOS / Debian:

```bash
./scripts/verify-workstation.sh
```

Verification is profile-aware: it does not report Docker or `kind` as missing on the Windows ARM64 VMware Fusion client-tools-only profile.

## Idempotence

A release/profile validation requires a successful first bootstrap, verification, then a successful second bootstrap and verification without duplicate profile content or unintended reinstall behavior.
