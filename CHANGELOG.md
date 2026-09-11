# Changelog

## 1.5.1 - 2026-09-10

- Accept Debian 11 and newer, Ubuntu and APT derivatives; add Fedora and openSUSE Leap/Tumbleweed installers.
- Route Linux packages through APT, DNF or Zypper and adapt Docker, Azure, Kubernetes and HashiCorp installation.
- Complete the Debian base toolchain and correct azd ARM64 archive handling.
- Accept preinstalled stable azd 1.31.1 or newer on Linux; give an actionable error for older versions. Clean installations retain pinned, checksum-verified artifacts.
- Automate macOS container setup with Colima and keep module-specific installation within each module.
- Update quick-start instructions and platform tests.

Validation: automated Bash/macOS/Windows checks, Debian 12 ARM64 first/second runs, RPM container checks, and user-reported Debian 13 bootstrap and Dell Ubuntu 26 workstation verification. Full Fedora/openSUSE Docker runtime validation and openSUSE x86_64 Vagrant execution remain outstanding. openSUSE ARM64 requires an existing Vagrant installation to use the HashiCorp module.

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
