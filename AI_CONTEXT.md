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

| Platform | Architecture | Runtime |
|---|---|---|
| macOS 14+ | Apple Silicon / arm64 | OrbStack |
| Debian 12 | amd64, arm64 | Docker Engine CE |
| Windows 11 23H2+ (build 22631+) | x64/amd64 | Rancher Desktop + Moby |

Windows uses native PowerShell for the bootstrap. Rancher Desktop uses WSL2 internally.

## Modules

`system_packages`, `containers`, `aws`, `azure`, `hashicorp`, `kubernetes`, `terminal`.

Module defaults are stored in `config/bootstrap.yaml`. Interactive selection is an execution-time override and must not rewrite the configuration file.

## Entry points

- macOS/Linux: `./bootstrap.sh`
- Windows: `.\bootstrap.ps1`

When run from an interactive terminal, both entry points present module selection. CI and unattended execution use `--non-interactive` or `-NonInteractive`.

## Release policy

Static CI is necessary but not sufficient. A release is production-validated only after a full first run and a second idempotence run on each supported platform, followed by the platform verification script.
