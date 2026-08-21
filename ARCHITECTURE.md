# Architecture

## Overview

Workstation Bootstrap exposes native entry points and platform-specific module implementations behind one module model.

```text
bootstrap.sh / bootstrap.cmd / bootstrap.ps1
            |
            +-- configuration + platform/capability detection
            |
            +-- system_packages
            +-- containers
            +-- aws
            +-- azure
            +-- hashicorp
            +-- kubernetes
            +-- terminal
```

## Container runtimes

- macOS Apple Silicon: OrbStack.
- Debian 12: Docker Engine CE.
- Windows x64/arm64 with required virtualization: Docker Desktop using the WSL2 Linux-container backend.
- Windows ARM64 under VMware Fusion on Apple Silicon: no local container runtime; the module exits successfully with an explicit capability warning.

The Windows capability gate is evaluated before WSL/Docker startup. The known VMware Fusion ARM64 profile is detected from Windows architecture and VMware computer-system metadata. This avoids installing or starting a runtime that cannot satisfy its virtualization prerequisites.

## Kubernetes

The Kubernetes module is client-first. `kubectl`, Helm 3, k9s and kubectx are independent of a local cluster. `kind` is installed and validated only when the platform can provide a supported local container runtime.

## Windows execution

Windows uses native PowerShell. `bootstrap.cmd` is the recommended launcher for fresh machines because it invokes `bootstrap.ps1` with a process-only execution-policy bypass.

Native external commands are executed through `Invoke-NativeCommand`, which evaluates process exit codes. Console encoding is normalized to UTF-8 before WinGet/native output is consumed.

WinGet source state is probed before package operations. The project repairs only the known `0x8a15000f` source-data-missing condition using the official Microsoft source package.

## Validation

Static CI checks structure, syntax and policy invariants. Runtime validation is profile-specific:

- local-container profiles: engine OS, Compose and `hello-world` are mandatory;
- Windows ARM64 VMware Fusion: Docker/`kind` are intentionally absent and verification checks the remaining client toolchain.
