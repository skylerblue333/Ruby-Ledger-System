# Sky Ledger Ruby Core

A focused Ruby 3.3 double-entry ledger primitive for validating and replaying balanced transaction batches. This repository is an engineering-beta accounting core, not a payment processor, bank ledger, or production financial system.

## Implemented behavior

- Native Ruby implementation with no application runtime dependencies.
- Double-entry invariant: every transaction must contain 2–100 non-zero entries whose minor-unit amounts sum exactly to zero.
- Integer minor-unit money representation; no floating-point accounting math.
- Three-letter uppercase currency validation.
- Bounded account and transaction identifiers.
- ISO-8601 transaction timestamps.
- Duplicate transaction-ID rejection.
- Deterministic SHA-256 digest of normalized transaction content.
- Deterministic transaction ordering and per-account/currency balance aggregation.
- JSON CLI for validating and replaying one transaction or a batch.
- Automated syntax, invariant, CLI, Docker, and non-root runtime checks.

## Example

```bash
cat <<'JSON' | ruby bin/sky-ledger
[
  {
    "id": "sale-001",
    "currency": "USD",
    "occurred_at": "2026-08-24T12:00:00Z",
    "entries": [
      { "account": "cash", "amount_minor": 2500 },
      { "account": "revenue", "amount_minor": -2500 }
    ]
  }
]
JSON
```

The CLI returns normalized transaction metadata and resulting balances. Invalid JSON exits with code 2; ledger validation failures exit with code 3.

## Verification

```bash
ruby -c lib/sky_ledger.rb
ruby -c bin/sky-ledger
ruby -Ilib:test test/test_ledger.rb
docker build -t sky-ruby-ledger .
```

CI additionally exercises the CLI and verifies that the container runs as a non-root user.

## Architecture

`SkyLedger::Ledger` owns process-local journal state. `post` validates and normalizes a transaction before atomically applying all of its entries to in-memory balances. Transaction digests are deterministic metadata, not signatures. `bin/sky-ledger` creates one ledger, replays JSON input, and emits a machine-readable result.

## SKYCOIN4444 integration

This component can serve as a deterministic accounting-domain library or validation sidecar for future SKYCOIN4444 finance/marketplace workflows. A durable integration should wrap the core with a transactional datastore, idempotency persistence, authorization, audit controls, reconciliation, backup/restore, and operational observability rather than treating this in-memory CLI as a financial system of record.

## Status and limitations

**Status: Engineering Beta.** Automated code/container verification is being established; deployment is not verified.

This repository does **not** provide durable storage, database transactions, cross-process locking, payment-provider integration, settlement, PCI handling, taxation, FX conversion, authorization/RBAC, tenant isolation, cryptographic signing, tamper-evident persistent journals, reconciliation workflows, HA, or production deployment. It should not be described as GA, production-ready, or financially compliant without separate evidence.

See `SECURITY.md` and `CHANGELOG.md` for boundaries and productization history.
