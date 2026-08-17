# Workstation Bootstrap

Workstation Bootstrap prepares reproducible workstations for cloud, DevOps and Kubernetes training.

## Supported platforms

| Platform | Architecture | Container runtime | Entry point |
|---|---|---|---|
| macOS 14+ | Apple Silicon (arm64) | OrbStack | `./bootstrap.sh` |
| Debian 12 | amd64 / arm64 | Docker Engine CE | `./bootstrap.sh` |
| Windows 11 23H2+ (build 22631+) | x64/amd64 | Rancher Desktop + Moby | `.\\bootstrap.ps1` |

Unsupported platforms fail during preflight before package installation. Windows requires WSL2 for Rancher Desktop, but the bootstrap itself runs natively in PowerShell.

## Quick start

### macOS / Debian

```bash
git clone https://github.com/ibmmo/workstation-bootstrap.git
cd workstation-bootstrap
./bootstrap.sh
./scripts/verify-workstation.sh
```

### Windows

From PowerShell:

```powershell
git clone https://github.com/ibmmo/workstation-bootstrap.git
Set-Location workstation-bootstrap
.\\bootstrap.ps1
.\\scripts\\verify-workstation.ps1
```

If the `containers` module is enabled, WSL2 must already be available. The bootstrap fails before package changes when it is missing.

## Modules

- `system_packages`
- `containers`
- `aws`
- `azure`
- `hashicorp`
- `kubernetes`
- `terminal`

Container runtime policy: OrbStack on macOS, Docker Engine on Debian, Rancher Desktop with Moby on Windows. Docker Desktop is not part of the baseline.

## Kubernetes baseline

The project currently standardizes on Kubernetes 1.36 tooling and Helm 3.21.4. `config/versions.env` contains the version baseline.

## Validation

```bash
./tests/run.sh
find . -type f -name '*.sh' -print0 | xargs -0 shellcheck
```

Windows static validation is provided by `tests/windows/test-static.ps1` and PSScriptAnalyzer in CI.

A release additionally requires fresh-host smoke tests and a second bootstrap run on each supported platform.

## Source-of-truth documents

- `AI_CONTEXT.md`
- `PROJECT_OVERVIEW.md`
- `CURRENT_STATE.md`
- `PROJECT_DECISIONS.md`

## Version

Current release candidate: **v1.4.1**.
