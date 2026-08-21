# Hardening Report

## Windows runtime and platform capability

- Docker Desktop + WSL2 is the Windows local-container baseline only when hardware virtualization is available.
- Windows ARM64 VMware Fusion guests on Apple Silicon are detected before WSL/Docker startup and treated as client-tools-only.
- The unsupported Fusion ARM64 profile exits the `containers` module successfully with an explicit warning instead of installing a runtime that cannot start.
- The Kubernetes module skips `kind` on that profile while preserving kubectl, Helm, k9s and kubectx.
- Docker startup is bounded through `docker desktop start --timeout` and failures include Desktop status and WSL state.
- Docker readiness requires Linux containers, Docker Compose and a successful `hello-world` run.
- Existing Docker Desktop installations are reused.

## Windows bootstrap robustness

- `bootstrap.cmd` provides a process-scoped execution-policy bypass without changing persistent policy.
- Native console input/output is normalized to UTF-8 to avoid WinGet mojibake.
- WinGet source error `0x8a15000f` is repaired using the official Microsoft source package and source refresh; unrelated failures are not silently repaired.
- Native command exit codes remain authoritative.
- Managed WinGet portable binaries are prioritized deterministically.

## Supply chain

- Prefer signed/vendor package repositories and first-party installers.
- Direct release downloads are checksum-verified when upstream publishes SHA-256 metadata.
- No credentials or environment secrets are embedded in the repository.

## Remaining release gates

- GUI/runtime behavior for OrbStack and Docker Desktop still requires real-host validation.
- Docker Desktop Windows ARM is vendor-described as Early Access and must satisfy Docker's hardware virtualization requirements.
- A first run, verification, second run and second verification remain mandatory for each released profile.
