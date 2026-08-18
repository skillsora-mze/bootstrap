# Release Checklist

## Static validation

- [ ] `./tests/run.sh` passes.
- [ ] ShellCheck passes on all Bash scripts.
- [ ] Windows PowerShell 5.1 parses every `.ps1` file.
- [ ] `tests/windows/test-static.ps1` passes under PowerShell 7.
- [ ] PSScriptAnalyzer reports no errors.
- [ ] CI passes on Ubuntu, macOS and Windows runners.

## Interactive behavior

- [ ] Default terminal launch presents module selection.
- [ ] Toggling modules changes only the current run.
- [ ] `config/bootstrap.yaml` remains unchanged after interactive runs.
- [ ] Bash `--non-interactive` and PowerShell `-NonInteractive` bypass prompts.

## macOS smoke test

- [ ] Full bootstrap succeeds on a clean supported Apple Silicon Mac.
- [ ] OrbStack starts and `docker info` succeeds.
- [ ] AWS SAM clean install uses the AWS first-party package and `sam --version` succeeds.
- [ ] `helm version --short` reports the Helm 3 baseline.
- [ ] Second full run succeeds without duplicate profile content.
- [ ] `scripts/verify-workstation.sh` succeeds.

## Debian smoke test

- [ ] Full bootstrap succeeds on clean Debian 12 amd64.
- [ ] Full bootstrap succeeds on clean Debian 12 arm64 if arm64 remains supported.
- [ ] Docker works for the normal user after re-login if group membership was added.
- [ ] `azd version` succeeds from the pinned verified artifact.
- [ ] Second full run succeeds.
- [ ] `scripts/verify-workstation.sh` succeeds.

## Windows smoke test

- [ ] Host is Windows 11 build 22631+ x64 with current WSL2 available.
- [ ] Full `.\bootstrap.ps1` succeeds from Windows PowerShell 5.1.
- [ ] Full `.\bootstrap.ps1` succeeds from PowerShell 7.
- [ ] Rancher Desktop first start does not require the setup wizard.
- [ ] Rancher Desktop uses Moby and embedded Kubernetes is disabled.
- [ ] A stale `desktop-linux` context is automatically changed to `default`.
- [ ] `aws --version` and `sam --version` succeed immediately after installation.
- [ ] `docker info`, `docker compose version`, `kubectl version --client`, `helm version --short`, `kind version` and `k9s version` succeed.
- [ ] Both Windows PowerShell and PowerShell 7 profile files contain exactly one managed block.
- [ ] Second full bootstrap run succeeds.
- [ ] `.\scripts\verify-workstation.ps1` succeeds.

## Release hygiene

- [ ] `docs/HARDENING_REPORT.md` reviewed.
- [ ] No credentials, tokens or private material are present.
- [ ] Source-of-truth documents match implementation.
- [ ] CHANGELOG/version updated.
- [ ] Feature branch -> CI -> PR -> merge to protected `main`.
- [ ] Tag created only after all smoke tests pass.
