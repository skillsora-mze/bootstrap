# Changelog

## 1.5.0 - Release candidate

### Added

- Interactive module selection on macOS/Linux and Windows.
- Explicit non-interactive mode for CI and unattended execution.
- Central Windows `Invoke-NativeCommand` wrapper based on native exit codes.
- Windows PowerShell 5.1 syntax validation in CI.
- Dual profile configuration for Windows PowerShell 5.1 and PowerShell 7.
- Pinned Azure Developer CLI 1.31.1 release metadata for Debian.

### Fixed

- Windows AWS SAM validation now resolves `sam`/`sam.cmd` instead of incorrectly requiring `sam.exe`.
- Rancher Desktop first-run no longer blocks the bootstrap on `rdctl start`.
- Rancher Desktop is started in background with Moby and embedded Kubernetes disabled.
- Stale Docker Desktop `desktop-linux` context is normalized to `default` on Windows.
- Native stderr warnings no longer abort Windows bootstrap commands when exit code is successful.
- WinGet pinned packages are no longer silently accepted at the wrong version; older versions are upgraded and automatic downgrades are blocked.
- Windows minimum build is consistently 22631 (Windows 11 23H2+) across code and documentation.
- GitHub Actions no longer duplicates feature-branch checks on both push and pull request.
- ShellCheck source warnings are scoped to the intentional dynamic-source lines.
- macOS test suite remains compatible with the system Bash 3.2 baseline.
- Repository clone URLs now point to `skillsora-mze/bootstrap`.

### Changed

- Clean macOS AWS SAM installations use the AWS first-party package installer rather than Homebrew.
- Debian `azd` installation uses pinned, checksum-verified release artifacts instead of a mutable installer script.

## 1.4.1

- Windows 11 23H2 support baseline.
- macOS Bash 3.2 test compatibility.

## 1.4.0

- Native Windows bootstrap introduced with Rancher Desktop/Moby.

## 1.3.0

- OrbStack standardized on macOS and Docker Engine on Debian.
