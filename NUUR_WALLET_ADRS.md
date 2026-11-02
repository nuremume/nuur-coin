# NUUR WALLET — Architecture Decision Records

This file tracks accepted product choices separately from proposed technical decisions. Proposed decisions must be reviewed before they are treated as implementation constraints. Each ADR is subject to the mandatory pre-implementation security gate in [`SECURITY_ENGINEERING_REQUIREMENTS.md`](./SECURITY_ENGINEERING_REQUIREMENTS.md) and the risks in [`NUUR_WALLET_THREAT_MODEL.md`](./NUUR_WALLET_THREAT_MODEL.md).

## ADR-001 — Custody is provided by a professional third party

- **Status:** Accepted product direction; provider and contract pending.
- **Context:** NUUR has selected a custodial product model. Private signing keys and provider signing secrets must not enter NUUR databases, caches, logs, analytics, or application bundles.
- **Decision:** Use an independently assessed professional custody provider for signing infrastructure and execution. NUUR services submit authorized intents and maintain customer/accounting state; they do not implement or hold customer signing keys.
- **Consequences:** Provider due diligence, API/webhook threat review, documented key lifecycle/recovery/rotation/exit procedures, contractual responsibility mapping, and provider-specific sandbox validation are mandatory before integration approval. Ordinary administrators and customer-support staff cannot gain signing authority.
- **Open items:** Provider, supported networks/assets, HSM/MPC architecture, approval policy, SLAs, provider idempotency/query guarantees, incident obligations, and exit mechanism.

## ADR-002 — Network and asset identities are explicit and network-specific

- **Status:** Proposed; exact registry schema and identifiers pending review.
- **Context:** EVM networks can share token symbols and even contract addresses; Solana assets use mint identifiers. Symbols and display names are not security identities.
- **Decision:** Resolve every operation against an approved network registry entry and an approved asset-on-network entry. Use immutable canonical identifiers, decimals, enabled state, provider support, and policy version. Unknown or disabled combinations fail closed.
- **Consequences:** UI labels are display-only; all API, ledger, deposit, withdrawal, custody, and reconciliation records include canonical network and asset identity. Changes require review, audit, and migration/version handling.
- **Open items:** Canonical ID representation per network, chain identity handshake, and initial approved contract/mint identifiers.

## ADR-003 — The internal double-entry ledger is the customer-balance authority

- **Status:** Proposed; accounting model requires finance/accounting and custody review.
- **Context:** Provider and chain balances may be delayed, incomplete, or divergent. They cannot safely substitute for NUUR's record of customer liabilities.
- **Decision:** PostgreSQL journal transactions and entries are authoritative for NUUR customer liabilities. Every posted journal balances per canonical asset/network. Posted records are append-only; corrections use authorized reversal/adjustment journals. Holds/reservations are explicit. Balances are derived from entries and holds; caches are rebuildable.
- **Consequences:** Ledger invariants, atomic posting, constraints, concurrency behavior, suspense handling, fee treatment, and provider/chain reconciliation must be proven before any customer funds are supported. Administrative roles cannot directly edit posted entries.
- **Open items:** Chart of accounts, liability/asset/suspense mapping, fee/rounding policy, deposit availability/finality, and accounting sign-off.

## ADR-004 — External events and financial commands are idempotent and durably processed

- **Status:** Proposed.
- **Context:** Providers and queues retry, webhooks may be duplicated or reordered, and network calls can time out after an operation is accepted.
- **Decision:** Use durable idempotency records, transactional outbox/inbox patterns, unique provider/chain event identities, explicit monotonic state transitions, and reconciliation for uncertain outcomes. Treat event delivery as at-least-once. Never blindly resubmit an unknown withdrawal.
- **Consequences:** Every event consumer and financial command needs replay/duplicate/race-condition tests before implementation. Provider-specific idempotency and lookup behavior must be documented. Unknown states remain visible and held pending reconciliation.
- **Open items:** Broker choice, retention/replay policy, outbox relay behavior, event identity per chain/provider, and provider query contract.

## ADR-005 — Start with a modular backend and separately permissioned workers

- **Status:** Proposed; review against team scale and provider deployment requirements.
- **Context:** Product modules need clear ownership and security boundaries, while premature distributed services add operational complexity and cross-service consistency risk.
- **Decision:** Begin with a modular NestJS backend organized by domain ownership, plus separately deployed worker processes for durable asynchronous jobs. Modules own writes and expose explicit interfaces. Split into separately deployable services when justified by blast-radius, regulatory isolation, scaling, or provider requirements.
- **Consequences:** Enforce module boundaries, database-role separation, dependency direction, and ownership tests/lint rules. Shared PostgreSQL does not imply unrestricted cross-module repository access. Staff/admin APIs remain a separate app and access plane.
- **Open items:** Team ownership, deployment topology, database schema separation, and provider isolation requirements.

## ADR-006 — Customer and staff administration use separate access planes

- **Status:** Accepted product/security requirement; implementation details pending.
- **Context:** Staff workflows can expose sensitive customer and financial information and may trigger restricted state changes. Support access must never confer custody signing authority.
- **Decision:** Provide a separate internal administration application and staff API boundary with a staff identity realm, strong authentication, narrow roles, maker-checker approvals for sensitive actions, and independent audit access controls.
- **Consequences:** Customer credentials cannot authorize staff access. Roles separate Support, Compliance, Finance/Reconciliation, Security, Custody Operations, and Administrator responsibilities. Posted ledger entries are not editable through the admin UI. Emergency access is time-bounded, independently reviewed, and audited.
- **Open items:** Staff identity integration, role/action matrix, step-up policy, approval quorum, emergency access procedure, and audit sink ownership.

## ADR-007 — Public API and provider callbacks are versioned, validated, and auditable

- **Status:** Proposed.
- **Context:** Customer APIs and provider callbacks cross untrusted boundaries and may be retried, malformed, replayed, or used to enumerate resources.
- **Decision:** Version public REST APIs and maintain OpenAPI contracts. Authenticate and authorize protected requests, validate input server-side, enforce resource-level access, use explicit CORS/security headers/rate limits, and verify provider callbacks before enqueueing. Errors do not disclose secrets, stack traces, or account existence.
- **Consequences:** API schema/permission changes require review and backward compatibility planning. Security tests must cover anonymous, cross-customer, staff/customer separation, malformed inputs, replay, and rate/resource constraints.
- **Open items:** API gateway, auth protocol, webhook verification specification, customer-visible state vocabulary, and WebSocket need per workflow.

## ADR-008 — Redis is non-authoritative and secrets remain outside application data stores

- **Status:** Accepted security requirement; implementation service selection pending.
- **Context:** Redis is useful for ephemeral coordination but cache loss, stale state, or broad access must not change financial truth. Provider credentials are high-impact secrets.
- **Decision:** PostgreSQL durable records govern balances, approvals, transaction state, and idempotency. Redis may hold rebuildable/expiring cache, rate-limit state, or coordination only. Provider credentials live in approved managed secrets infrastructure and are retrieved with least-privilege workload identity.
- **Consequences:** Redis outage cannot corrupt or create balance changes. Secret access is audited, scoped, rotated, and absent from logs, dumps, developer environments, and client bundles.
- **Open items:** Cloud secret service, encryption key ownership, cache TTL/data classification, and provider credential rotation mechanics.

## Decision log

| ADR | Decision | Status |
| --- | --- | --- |
| 001 | Professional third-party custody | Accepted product direction; provider pending |
| 002 | Network/asset identity registry | Proposed |
| 003 | Double-entry ledger is balance authority | Proposed |
| 004 | Idempotent durable event processing | Proposed |
| 005 | Modular backend plus isolated workers | Proposed |
| 006 | Separate customer/staff access planes | Accepted requirement; details pending |
| 007 | Versioned validated APIs and verified callbacks | Proposed |
| 008 | Redis non-authoritative; secrets externalized | Accepted security requirement; service pending |
