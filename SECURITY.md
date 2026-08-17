# Security

## Principles

- No credentials, tokens, private keys or cloud secrets are stored in this repository.
- Use short-lived cloud credentials and least privilege outside this bootstrap.
- Prefer signed vendor package repositories.
- Do not pipe downloaded network content directly to a shell.
- Use temporary directories for downloaded installers and archives.

## Supply-chain exceptions

Some tools do not expose a convenient signed system repository for the supported Linux platform. These exceptions are documented in `CURRENT_STATE.md` and must be reviewed at each release.

## Reporting

Do not include real credentials in issue reports, logs or screenshots.
