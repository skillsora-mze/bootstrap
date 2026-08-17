# Contributing

## Workflow

Do not work directly on `main` for feature changes.

```bash
git switch -c feature/<short-name>
```

Keep changes small and reversible. User-visible changes must update the source-of-truth documents and CHANGELOG when applicable.

## Required local validation

```bash
./tests/run.sh
find . -type f -name '*.sh' -print0 | xargs -0 shellcheck
```

## Release validation

Before merge/release, run the complete bootstrap and `scripts/verify-workstation.sh` on:

- macOS 14+ Apple Silicon
- Debian 12 amd64 or arm64 (at least one architecture per change; both for platform-sensitive changes)

Record validation results in the pull request.

## Commit examples

```text
feat: add workstation capability
fix: make container runtime setup idempotent
test: add bootstrap regression coverage
docs: update supported platform matrix
```

## Release sequence

1. Commit on a feature branch.
2. Run tests and ShellCheck.
3. Smoke-test supported platforms.
4. Update documentation and CHANGELOG.
5. Merge through pull request.
6. Tag the validated release.
