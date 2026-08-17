# Rollback Guide

Workstation Bootstrap intentionally does not provide an automatic destructive uninstall command. Rollback is platform-specific and should be performed only when required.

## Shell customization

Safe rollback:

1. Remove `~/.training_aliases`.
2. Remove the marked `# Workstation Bootstrap training aliases` block from `.zshrc` or `.bashrc`.

## macOS

Packages are managed by Homebrew. Review installed dependencies before uninstalling because tools may be shared with other workflows.

OrbStack can be removed with Homebrew only when container labs are no longer required:

```bash
brew uninstall --cask orbstack
```

## Debian

Do not remove APT repositories or packages automatically from training machines that may use them outside this project.

Repository files created by this project are:

```text
/etc/apt/sources.list.d/docker.sources
/etc/apt/sources.list.d/azure-cli.sources
/etc/apt/sources.list.d/hashicorp.list
/etc/apt/sources.list.d/kubernetes.list
```

Keyrings created by this project are under `/etc/apt/keyrings/` plus `/etc/apt/keyrings/hashicorp-archive-keyring.gpg`.

Before deleting anything, inspect package ownership and operational dependencies. Prefer restoring from the workstation image/snapshot when one is available.
