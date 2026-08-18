# v1.5.0 Hardening Report

This report records the defects addressed before the v1.5.0 real-host validation cycle.

## Windows defects addressed

- Rancher Desktop first-run startup is asynchronous and configured for Moby with embedded Kubernetes disabled.
- A stale Docker Desktop `desktop-linux` context is changed to `default` before Docker validation.
- Native command execution is centralized in `Invoke-NativeCommand`; native exit codes determine success and benign stderr does not terminate the bootstrap.
- AWS SAM is resolved as `sam`/`sam.cmd`, not the non-existent `sam.exe` assumption.
- Pinned WinGet packages are checked for version drift; older versions are upgraded and newer versions are never downgraded automatically.
- Both Windows PowerShell 5.1 and PowerShell 7 user profiles receive the managed terminal block idempotently.
- CI parses all PowerShell under Windows PowerShell 5.1 and regression-tests native stderr handling in both 5.1 and PowerShell 7.

## Cross-platform defects addressed

- Interactive module selection is available on Bash and PowerShell and does not rewrite `config/bootstrap.yaml`.
- The Bash dispatcher executes the selected module set directly instead of re-filtering against YAML defaults.
- macOS system Bash 3.2 compatibility is retained in the test suite.
- Helm 3 is kept as the lab baseline instead of following the unversioned Helm 4 package line.
- Clean macOS AWS SAM installs use the AWS first-party package installer.
- Debian `azd` uses pinned release artifacts with SHA-256 verification instead of a mutable network-to-shell installer.
- Windows minimum build, repository URLs, versions and documentation are aligned.

## Validation completed in build environment

- `./tests/run.sh`
- `bash -n` for all Bash scripts
- structural regression checks for stale URLs, stale Windows build requirements, legacy module names and known command-resolution mistakes

## Validation delegated to CI

- ShellCheck
- Windows PowerShell 5.1 parsing
- Windows native-command regression test under Windows PowerShell 5.1
- Windows static tests under PowerShell 7
- Windows native-command regression test under PowerShell 7
- PSScriptAnalyzer (errors)
- macOS Bash/Homebrew static validation

## Release gates still required

Static validation cannot prove GUI/runtime first-run behavior. Before tagging v1.5.0, complete `docs/RELEASE_CHECKLIST.md`, including a first run and a second idempotence run on each supported platform.
