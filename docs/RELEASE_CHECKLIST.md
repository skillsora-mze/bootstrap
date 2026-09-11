# Release Checklist

## Common

- [ ] Static test suite passes.
- [ ] No credentials/secrets are present.
- [ ] Documentation and source-of-truth files match the implementation.
- [ ] First bootstrap completes for the tested profile.
- [ ] Platform verification succeeds.
- [ ] Second bootstrap completes without unintended reinstall/profile duplication.
- [ ] Second platform verification succeeds.

## macOS Apple Silicon

- [ ] macOS 14+ arm64 host.
- [ ] Colima starts and Docker-compatible commands work.
- [ ] Full selected toolchain verifies.

## Linux

- [ ] Debian 11, 12 and 13 amd64 first-run/idempotence passes.
- [ ] Debian 11, 12 and 13 arm64 first-run/idempotence passes if released.
- [ ] Docker Engine, Compose and Kubernetes client/local tooling verify.

## Windows x64 container profile

- [ ] Windows 11 build 22631+ x64.
- [ ] Current WSL2 is available.
- [ ] Docker Desktop starts with WSL2 backend.
- [ ] `docker info --format '{{.OSType}}'` returns `linux`.
- [ ] `docker compose version` succeeds.
- [ ] `docker run --rm hello-world` prints the success marker.
- [ ] `kind version` succeeds.
- [ ] Full verification passes twice.

## Windows ARM64 container-capable profile

- [ ] Windows 11 build 22631+ ARM64 on hardware/hypervisor that exposes required virtualization.
- [ ] Docker Desktop ARM installation and startup are validated on the actual target environment.
- [ ] Linux-engine, Compose, hello-world and `kind` checks pass.
- [ ] Full verification passes twice.

## Windows ARM64 VMware Fusion / Apple Silicon profile

- [x] Guest is detected as VMware + ARM64.
- [x] Bootstrap reports client-tools-only/local-containers skipped.
- [x] Docker Desktop is not required or installed by the bootstrap for this profile.
- [x] `kind` is not required or installed by the Kubernetes module.
- [x] Git/PowerShell/Python/Go/jq/yq/ripgrep/starship verify when selected.
- [x] AWS/Azure/HashiCorp tools verify when selected.
- [x] kubectl/Helm/k9s/kubectx verify when selected.
- [x] First run and second idempotence run both pass.

- [ ] Ubuntu and Linux Mint first-run/idempotence passes.

- [ ] Fedora: system packages, Kubernetes, Azure, HashiCorp and Docker first-run/idempotence.
- [ ] openSUSE Leap and Tumbleweed: first-run/idempotence; verify Vagrant limitation on ARM64.

### RPM support validation (2026-09-09)

- [x] Bash tests, ShellCheck and whitespace checks pass locally.
- [x] Fedora 44 ARM64 disposable container: system_packages, Kubernetes, Azure
  and HashiCorp modules install and pass their CLI checks.
- [x] openSUSE Tumbleweed ARM64 disposable container: system_packages,
  Kubernetes and Azure modules install and pass their CLI checks.
- [x] Fedora 44 and Tumbleweed ARM64: Docker/Compose packages install and a second
  installer run succeeds. Service startup and daemon health were stubbed; no
  Docker daemon was started inside these containers.
- [x] Leap 15.6 ARM64: native package dependency resolution succeeds (dry run).
- [ ] openSUSE x86_64 HashiCorp runtime: test host cannot execute x86_64 containers
  (`exec format error`); the Vagrant RPM remains to be exercised on x86_64.
- [ ] Full workstation installation with systemd and a running Docker daemon.

### User-reported host validation (2026-09-10)

- [x] Debian 13: user confirmed bootstrap succeeds after the platform correction.
- [x] Dell PC, Ubuntu 26: user confirmed workstation validation succeeds after addressing azd 1.28.1. Exact resulting azd version was not provided.
- [ ] Second bootstrap and verification on that Dell host.
