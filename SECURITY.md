# Security Policy

Sky Ledger Ruby Core is an engineering-beta accounting primitive, not a production financial system.

## Current boundary

The ledger is process-local and in-memory. The CLI accepts caller-supplied JSON and does not authenticate callers, persist journals, encrypt records, sign transactions, or enforce tenant boundaries. Transaction SHA-256 digests provide deterministic fingerprints only; they are not digital signatures or tamper-proof storage.

## Safe operating guidance

- Use integer minor units only; do not convert floating-point values into ledger entries without a separately reviewed conversion policy.
- Validate all upstream identities and authorization before constructing transactions.
- Keep secrets, payment-card data, bank credentials, and sensitive personal data out of transaction IDs and account names.
- Add durable idempotency, transactional persistence, append-only audit controls, backups, reconciliation, and access controls before using the core in a system of record.
- Run the supplied container as its non-root user.

## Unsupported claims

The repository does not establish PCI compliance, SOX controls, banking compliance, settlement correctness, tax correctness, cryptographic non-repudiation, HA, or production deployment security.

## Reporting

Use GitHub private vulnerability reporting when enabled. Avoid publishing exploitable details before a remediation is available.
