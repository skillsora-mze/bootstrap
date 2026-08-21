# AI Context

## Project

Workstation Bootstrap prepares reproducible training workstations for cloud, DevOps and Kubernetes labs.

## Source-of-truth order

1. `AI_CONTEXT.md`
2. `PROJECT_OVERVIEW.md`
3. `CURRENT_STATE.md`
4. `PROJECT_DECISIONS.md`

Implementation and documentation must remain aligned with these files.

## Principles

- simplicity
- modularity
- idempotence
- configuration-driven behavior
- explicit multi-platform support
- safe, reversible changes
- no embedded credentials
- vendor-supported installation methods where practical

## Supported platforms

| Platform | Architecture | Runtime / profile |
|---|---|---|
| macOS 14+ | Apple Silicon / arm64 | OrbStack |
| Debian 12 | amd64, arm64 | Docker Engine CE |
| Windows 11 23H2+ (build 22631+) | x64/amd64 | Docker Desktop + WSL2 + Linux containers |
| Windows 11 23H2+ (build 22631+) | arm64 | Native Windows tooling; Docker Desktop only when hardware virtualization is exposed |
| Windows 11 ARM64 guest on VMware Fusion / Apple Silicon | arm64 | Client-tools-only profile; local containers and `kind` are skipped |

Windows uses native PowerShell. Docker Desktop is used only when the Windows environment exposes the virtualization required by WSL2. VMware Fusion on Apple Silicon does not expose nested virtualization to Windows ARM guests, so local Docker and `kind` are not part of that profile.

## Modules

`system_packages`, `containers`, `aws`, `azure`, `hashicorp`, `kubernetes`, `terminal`.

Module defaults are stored in `config/bootstrap.yaml`. Interactive selection is an execution-time override and must not rewrite the configuration file. On a Windows ARM64 VMware guest, the `containers` module is safely skipped and the `kubernetes` module installs client tooling without `kind`.

## Entry points

- macOS/Linux: `./bootstrap.sh`
- Windows: `.\bootstrap.cmd` (recommended) or `.\bootstrap.ps1`

`bootstrap.cmd` launches PowerShell with a process-scoped execution-policy bypass so a fresh Windows workstation can run the project without changing machine policy. Interactive launches present module selection; CI and unattended execution use `--non-interactive` or `-NonInteractive`.

## Release policy

Static CI is necessary but not sufficient. A release is production-validated only after the applicable first-run and second-run idempotence checks in `docs/RELEASE_CHECKLIST.md` pass for each supported profile, followed by the platform verification script.
