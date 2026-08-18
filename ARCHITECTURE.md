# Architecture

## Entry points

```text
macOS / Debian                    Windows
./bootstrap.sh                    .\bootstrap.ps1
      |                                  |
      +-- platform/config                +-- platform/config
      +-- interactive selection          +-- interactive selection
      +-- module dispatcher              +-- module dispatcher
                  \                      /
                   config/bootstrap.yaml
                   config/versions.env
```

Interactive selection is an in-memory override. It does not modify configuration files.

## Modules

Each logical module lives under `scripts/modules/<module>/` and has Bash and PowerShell implementations where supported.

Execution order is fixed:

1. `system_packages`
2. `containers`
3. `aws`
4. `azure`
5. `hashicorp`
6. `kubernetes`
7. `terminal`

A user may disable a module for a run, but selected modules retain this order.

## Windows execution model

Windows uses native PowerShell. WSL2 is a prerequisite only for Rancher Desktop. External commands are executed through `Invoke-NativeCommand`, which captures output and evaluates `$LASTEXITCODE` rather than treating stderr text as a failure.

Rancher Desktop is started in background through `rdctl`, configured with Moby and Kubernetes disabled, and the Docker context is normalized to `default` before validation.

## Configuration

`config/bootstrap.yaml` contains stable feature defaults and platform policy. `config/versions.env` contains version/hash baselines shared by Bash and PowerShell.

The YAML reader intentionally supports the project's small fixed schema; it is not a general YAML parser.

## Verification

- `tests/run.sh`: local Bash/static structural tests.
- GitHub Actions: Ubuntu ShellCheck/tests, macOS Bash/Brewfile validation, Windows PowerShell 5.1 parse + PowerShell 7 static analysis.
- `scripts/verify-workstation.sh` and `.ps1`: host runtime verification.
