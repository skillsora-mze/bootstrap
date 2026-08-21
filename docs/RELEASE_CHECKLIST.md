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
- [ ] OrbStack starts and Docker-compatible commands work.
- [ ] Full selected toolchain verifies.

## Debian 12

- [ ] Debian 12 amd64 first-run/idempotence passes.
- [ ] Debian 12 arm64 first-run/idempotence passes if released.
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
