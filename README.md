# Workstation Bootstrap

Cross-platform workstation bootstrap for AWS, Azure, Infrastructure as Code, Kubernetes and container training labs.

## Supported platforms

| Platform | Architecture | Container runtime |
|---|---|---|
| macOS 14+ | Apple Silicon | OrbStack |
| Debian 12 | amd64 / arm64 | Docker Engine CE |
| Windows 11 23H2+ (build 22631+) | x64 | Rancher Desktop + Moby |

Windows requires WSL2 for Rancher Desktop. Docker Desktop is not the project baseline.

## Install

macOS / Debian:

```bash
git clone https://github.com/skillsora-mze/bootstrap.git
cd bootstrap
./bootstrap.sh
```

Windows PowerShell:

```powershell
git clone https://github.com/skillsora-mze/bootstrap.git
Set-Location bootstrap
.\bootstrap.ps1
```

Interactive terminal runs display the module list before making package changes. Toggle module numbers and press Enter to continue.

For CI or unattended execution:

```bash
./bootstrap.sh --non-interactive
```

```powershell
.\bootstrap.ps1 -NonInteractive
```

## Modules

`system_packages`, `containers`, `aws`, `azure`, `hashicorp`, `kubernetes`, `terminal`.

Defaults are stored in `config/bootstrap.yaml`; interactive choices apply only to the current run.

## Verify

macOS / Debian:

```bash
./scripts/verify-workstation.sh
```

Windows:

```powershell
.\scripts\verify-workstation.ps1
```

## Release status

Version 1.5.0 is a release candidate until the real-host first-run and idempotence checks in `docs/RELEASE_CHECKLIST.md` pass on every supported platform.
