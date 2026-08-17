# Release Checklist

## Static validation

- [ ] `./tests/run.sh` passes.
- [ ] ShellCheck passes on all Bash scripts.
- [ ] Windows `tests/windows/test-static.ps1` passes.
- [ ] PSScriptAnalyzer reports no errors.
- [ ] CI passes on Ubuntu, macOS and Windows runners.

## macOS smoke test

- [ ] Full bootstrap succeeds on a clean supported Apple Silicon Mac.
- [ ] `orb status`, `docker info`, `helm version --short` and `kind version` succeed.
- [ ] Helm reports v3.21.4 baseline.
- [ ] Second `./bootstrap.sh` run succeeds without duplicate profile content.
- [ ] `scripts/verify-workstation.sh` succeeds.

## Debian smoke test

- [ ] Full bootstrap succeeds on clean Debian 12 amd64.
- [ ] Full bootstrap succeeds on clean Debian 12 arm64 if arm64 remains in release support.
- [ ] `docker info` succeeds as the normal user after re-login.
- [ ] Second `./bootstrap.sh` run succeeds.
- [ ] `scripts/verify-workstation.sh` succeeds.

## Windows smoke test

- [ ] Test host is Windows 11 build 22631+ x64 with WSL2 available.
- [ ] Full `.\\bootstrap.ps1` succeeds from native PowerShell.
- [ ] Rancher Desktop starts with Moby and embedded Kubernetes disabled.
- [ ] `docker info`, `docker compose version`, `kubectl version --client`, `helm version --short`, `kind version` and `k9s version` succeed.
- [ ] Second `.\\bootstrap.ps1` run succeeds without duplicate PowerShell profile content.
- [ ] `.\\scripts\\verify-workstation.ps1` succeeds.

## Release hygiene

- [ ] No credentials, tokens or private material are present in the diff.
- [ ] Source-of-truth documents match the implementation.
- [ ] CHANGELOG and version are updated.
- [ ] Release branch/PR is reviewed before merge to `main`.
- [ ] Tag is created only after all supported-platform smoke tests pass.
