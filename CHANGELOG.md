# Changelog

## v1.4.1 - Release candidate

### Fixed

- Windows 11 minimum aligned to 23H2 (build 22631+) after real-host preflight validation.
- macOS test suite made compatible with the system Bash 3.2 by removing `mapfile`.
- Documentation and release checklist aligned with the Windows 11 23H2 baseline.

### Added

- Native Windows PowerShell entry point (`bootstrap.ps1`).
- Windows 11 23H2+ x64 support with WinGet.
- Rancher Desktop container runtime on Windows configured with Moby and embedded Kubernetes disabled.
- WSL2 fail-fast preflight before Windows package changes when containers are enabled.
- Windows package manifest, module implementations, workstation verification and static tests.
- Windows and macOS static CI jobs.

### Changed

- Helm training baseline updated to 3.21.4.
- macOS now uses Homebrew `helm@3` because the unversioned formula follows Helm 4.
- Windows terminal integration copies managed content to `~/.workstation-bootstrap` rather than referencing the repository path.
- Documentation and support matrix now cover all three supported OS families.

### Limitations

- Windows ARM64 is not supported in v1.4.1.
- Ansible is not installed as a native Windows control node; WSL2 is the supported path for Ansible labs.
- Runtime smoke testing on real supported hosts remains a release gate.

## v1.3.0

- Replaced Docker Desktop assumptions on macOS with OrbStack.
- Renamed the `docker` module to `containers`.
- Restricted Linux support to Debian 12 amd64/arm64.
- Added source-of-truth documentation, static tests and CI.
- Added signed APT repository setup and supply-chain hardening.

## v1.2.0

Previous stable baseline.
