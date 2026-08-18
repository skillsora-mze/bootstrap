# Workstation Bootstrap Architecture

## Execution flow

```text
macOS / Debian                         Windows
bootstrap.sh                           bootstrap.ps1
    |                                     |
platform preflight                    Windows/WinGet/WSL2 preflight
    |                                     |
bootstrap.yaml + versions.env         bootstrap.yaml + versions.env
    |                                     |
enabled modules                       enabled modules
    |                                     |
install.sh modules                    install.ps1 modules
    \____________ module verification ____________/
```

## Repository structure

```text
.
├── bootstrap.sh
├── bootstrap.ps1
├── config/
│   ├── bootstrap.yaml
│   └── versions.env
├── packages/
│   ├── debian/packages.txt
│   ├── macos/Brewfile
│   └── windows/packages.psd1
├── scripts/
│   ├── lib/
│   ├── linux/
│   ├── macos/
│   ├── windows/
│   ├── modules/
│   ├── verify-workstation.sh
│   └── verify-workstation.ps1
├── tests/
└── .github/workflows/ci.yml
```

## Platform model

### macOS

- macOS 14+
- Apple Silicon only
- Homebrew
- OrbStack

### Debian

- Debian 12
- amd64 / arm64
- APT + signed vendor repositories
- Docker Engine CE

### Windows

- Windows 11 23H2+, build 22631+
- x64/amd64
- native PowerShell + WinGet
- WSL2 prerequisite for Rancher Desktop
- Rancher Desktop configured with Moby and embedded Kubernetes disabled

## Configuration-driven design

Feature toggles are common across all platforms in `config/bootstrap.yaml`. Versions shared by platform-specific implementations are in `config/versions.env`. OS-specific package manifests live below `packages/`.

## Idempotence

Package managers skip already-installed packages where practical. Profile integration uses markers. Managed Windows terminal content is copied to `~/.workstation-bootstrap` so moving the repository does not break the profile. Downloads use unique temporary directories and are removed after execution.

## Supply chain

Signed vendor repositories/package managers are preferred. Direct pinned release downloads use upstream SHA-256 metadata where available. Network content is never piped directly into Bash or PowerShell.
