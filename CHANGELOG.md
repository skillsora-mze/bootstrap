# Changelog

## 1.5.0 - Release candidate finalization

### Windows

- Standardized the Windows local container runtime on Docker Desktop + WSL2 where virtualization prerequisites are available.
- Added Windows ARM64 package/tooling support and architecture-aware Helm downloads.
- Added explicit Windows ARM64 VMware Fusion / Apple Silicon client-tools-only capability detection; local Docker and `kind` are skipped on that profile.
- Added a Windows `bootstrap.cmd` launcher using process-scoped `ExecutionPolicy Bypass`.
- Added UTF-8 console normalization to prevent WinGet progress-output mojibake.
- Added targeted WinGet source repair for `0x8a15000f` source-data-missing failures.
- Added Docker Linux-engine, Compose and `hello-world` smoke tests for container-capable Windows profiles.
- Updated verification and tests to be profile-aware.

### Cross-platform

- Preserved OrbStack on macOS Apple Silicon and Docker Engine CE on Debian 12.
- Preserved modular, idempotent, configuration-driven execution.
- Updated source-of-truth and release documentation to match the final support matrix.
