# Rollback

## General

Workstation Bootstrap prefers additive, reversible changes. Package removal is never performed automatically as part of a rollback.

## Git rollback

Before release, keep changes on a feature branch. To abandon an unmerged branch, switch back to `main` and delete the feature branch only after confirming no work is needed.

After merge, revert the merge/commit through normal Git history rather than manually editing installed workstations.

## Windows profile changes

The Windows ARM64 VMware Fusion capability gate only changes bootstrap behavior: it skips local Docker and `kind`. Rolling it back means reverting the project commit; it does not require deleting user data.

The `bootstrap.cmd` execution-policy bypass is process-scoped and leaves no persistent policy change.

WinGet source repair only runs for the known source-data-missing condition and restores Microsoft default source metadata.
