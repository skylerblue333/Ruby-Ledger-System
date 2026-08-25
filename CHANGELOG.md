# Changelog

## Unreleased

### Added
- Native Ruby 3.3 double-entry ledger core.
- Balanced transaction validation using integer minor units.
- Duplicate transaction-ID rejection.
- Deterministic SHA-256 transaction fingerprints.
- Per-currency/account balance aggregation.
- JSON batch replay CLI.
- Ruby syntax/invariant tests and container smoke CI.
- Security and SKYCOIN4444 integration documentation.

### Changed
- Replaced the unrelated Python priority-job queue with an actual Ruby ledger implementation while retaining Git history.
- Replaced the Python runtime image with a non-root Ruby image.
- Repositioned the repository as an engineering-beta accounting primitive.

### Known limitations
- In-memory state only.
- No persistent journal, database transaction boundary, RBAC, signatures, reconciliation workflow, HA, compliance validation, or verified production deployment.
