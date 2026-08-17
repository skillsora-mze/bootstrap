# Project Decisions

## D001 - OrbStack on macOS

**Decision:** Use OrbStack as the only macOS container runtime.

**Reason:** It provides the Docker-compatible engine/CLI required by Compose and kind while avoiding Docker Desktop.

## D002 - Explicit support matrix

**Decision:** Support macOS 14+ Apple Silicon, Debian 12 amd64/arm64, and Windows 11 24H2+ x64.

**Reason:** Every enabled module must have an explicit, testable platform behavior. Detection alone does not imply support.

## D003 - Container module naming

**Decision:** Use the platform-neutral `containers` module.

**Reason:** Runtime implementation is platform-specific: OrbStack, Docker Engine, or Rancher Desktop/Moby.

## D004 - Configuration split

**Decision:** Keep feature toggles in `config/bootstrap.yaml` and validated toolchain versions in `config/versions.env`.

**Reason:** Both Bash and PowerShell can consume the configuration without adding a YAML parser prerequisite.

## D005 - Module isolation

**Decision:** Execute Bash modules in subshells and PowerShell modules as strict scripts.

**Reason:** Module state should not accidentally leak into later modules.

## D006 - Supply-chain preference

**Decision:** Prefer signed vendor repositories and package managers. Direct release downloads must be version-pinned and checksum-verified when upstream publishes checksum metadata. Network content must never be piped directly to a shell.

## D007 - Release validation

**Decision:** Static CI is necessary but not sufficient. A release requires a fresh-host smoke test and a second idempotence run on every supported platform.

## D008 - Native Windows entry point

**Decision:** Windows uses `bootstrap.ps1` and WinGet rather than Git Bash or running the bootstrap inside WSL.

**Reason:** Native PowerShell gives predictable Windows path, package and profile behavior while preserving the project structure.

## D009 - Rancher Desktop on Windows

**Decision:** Use Rancher Desktop with Moby (`dockerd`) and disable its embedded Kubernetes cluster.

**Reason:** The project needs a Docker-compatible API for Compose and kind without making Docker Desktop the baseline. WSL2 is an explicit prerequisite of this runtime.

## D010 - Windows x64 baseline

**Decision:** v1.4.0 supports Windows 11 build 26100+ on x64 only.

**Reason:** Narrow support reduces package/runtime variation for training fleets. Windows ARM64 can be added only after all modules are validated there.

## D011 - Helm 3 baseline

**Decision:** Standardize on Helm 3.21.4 for current labs.

**Reason:** Homebrew's unversioned `helm` package now follows Helm 4. macOS therefore uses `helm@3`; Windows installs the pinned Helm 3 release archive with SHA-256 verification.
