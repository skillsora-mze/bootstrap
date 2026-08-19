# v1.5.0 Hardening Report

This report records the defects addressed before the v1.5.0 real-host validation cycle.

## Windows defects addressed

- Rancher Desktop startup is bounded and no longer detaches `rdctl start`, so immediate startup failures are captured instead of being discarded.
- Automated Rancher Desktop startup uses `--no-modal-dialogs`, Moby, embedded Kubernetes disabled and updater disabled.
- A running Docker Desktop backend is detected before starting Rancher Desktop; the bootstrap stops with an explicit non-destructive conflict message instead of waiting for a runtime that may never acquire its backend resources.
- Rancher Desktop readiness failures include WSL distribution state and available Rancher Desktop log tails for actionable diagnostics.
- Existing Rancher Desktop settings are checked before `rdctl set`; a backend-restarting settings update is avoided when the required baseline is already active.
- Rancher Desktop's own `docker.exe` is resolved explicitly for runtime validation instead of trusting a global `docker` command that may be shadowed by Docker Desktop.
- The managed PowerShell profile prioritizes project-managed tools first and Rancher Desktop's `~/.rd/bin` second, reducing command shadowing across terminal sessions.
- A stale Docker Desktop `desktop-linux` context is changed to `default` before Docker validation.
- Native command execution is centralized in `Invoke-NativeCommand`; native exit codes determine success and benign stderr does not terminate the bootstrap.
- AWS SAM is resolved as `sam`/`sam.cmd`, not the non-existent `sam.exe` assumption.
- Pinned WinGet packages are checked for version drift; older versions are upgraded and newer versions are never downgraded automatically.
- WinGet portable Kubernetes tools are published to the project-managed bin directory so bundled copies from Docker/Rancher Desktop cannot silently win command resolution.
- Both Windows PowerShell 5.1 and PowerShell 7 user profiles receive the managed terminal block idempotently.
- CI parses all PowerShell under Windows PowerShell 5.1 and regression-tests native stderr handling in both 5.1 and PowerShell 7.

## Cross-platform defects addressed

- Interactive module selection is available on Bash and PowerShell and does not rewrite `config/bootstrap.yaml`.
- The Bash dispatcher executes the selected module set directly instead of re-filtering against YAML defaults.
- macOS `system_packages` no longer installs container, cloud, HashiCorp or Kubernetes module payloads indirectly through the base Brewfile. Each feature module owns its macOS package installation, so disabling a module now has real installation semantics.
- Package-manager stable channels and pinned direct artifacts use different validation policies: stable-channel tools are validated for compatibility, while pinned direct artifacts remain exact-version validated.
- Debian kubectl follows the configured Kubernetes minor repository and is validated as that minor line rather than a single patch that the repository can legitimately advance beyond.
- Direct Linux downloads for Helm, kind and k9s are checksum-verified using upstream-published SHA-256 metadata.
- macOS system Bash 3.2 compatibility is retained in the test suite.
- Helm 3 is kept as the lab baseline instead of following the unversioned Helm 4 package line.
- Clean macOS AWS SAM installs use the AWS first-party package installer.
- Debian `azd` uses pinned release artifacts with SHA-256 verification instead of a mutable network-to-shell installer.
- Workstation verification checks the Docker runtime only when the containers module is enabled.
- Windows minimum build, repository URLs, versions and documentation are aligned.

## Known residual risks

- AWS CLI v2 on Linux still follows AWS's current first-party installer endpoint and is not repository-pinned by SHA-256.
- Homebrew itself is bootstrapped from Homebrew's official current installer rather than a repository-pinned installer revision.
- GUI/runtime startup for OrbStack and Rancher Desktop cannot be proven by static CI and remains a real-host release gate.
- Stable package-manager channels can advance after this release; module validation therefore checks the project's compatibility contract rather than claiming an exact patch pin where no exact package pin is enforced.

## Automated validation

- `./tests/run.sh`
- Bash syntax and ShellCheck
- structural regression tests for module ownership, stale URLs, Windows build requirements and known command-resolution mistakes
- Windows PowerShell 5.1 parsing
- Windows native-command regression tests under Windows PowerShell 5.1 and PowerShell 7
- Windows static tests under PowerShell 7
- PSScriptAnalyzer errors
- macOS Bash/Homebrew static validation

## Release gates still required

Static validation cannot prove GUI/runtime first-run behavior. Before tagging v1.5.0, complete `docs/RELEASE_CHECKLIST.md`, including a first run, second idempotence run and workstation verification on every supported platform.
