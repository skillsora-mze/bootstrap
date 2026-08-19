# Security

## Principles

- Never store credentials, access tokens, SSH private keys or cloud secrets in this repository.
- Prefer signed vendor repositories and first-party package managers/installers.
- Direct release downloads must be version-pinned and SHA-256 verified when upstream publishes hashes.
- Network content must not be piped directly into a shell.
- Automatic destructive remediation is avoided: conflicting runtimes/packages and unsupported downgrades stop with an explicit message.

## Current controls

- Docker, Microsoft Azure CLI, HashiCorp and Kubernetes use signed APT repositories on Debian where applicable.
- AWS SAM and selected standalone tooling use pinned release artifacts with checksum validation.
- Azure Developer CLI on Debian uses pinned official release artifacts with published SHA-256 values.
- Windows native commands are evaluated by exit code; stderr text alone does not determine failure.
- No credential provisioning is performed by the bootstrap.

## Reporting

Do not include secrets or private infrastructure data in an issue. Report security-sensitive problems privately to the repository owner.
