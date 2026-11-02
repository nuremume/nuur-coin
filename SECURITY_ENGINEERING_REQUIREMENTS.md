# NUUR WALLET — Mandatory Feature Security Gate

These requirements apply to every NUUR WALLET feature, including customer mobile/web screens, backend APIs, ledger and transaction behavior, staff administration, integrations, infrastructure, and prototypes that shape security-sensitive workflows. Section 5 of the NUUR WALLET master specification is mandatory engineering policy.

No feature implementation begins until its security review and relevant security tests are written and reviewed. A feature must not weaken, remove, or bypass a requirement to simplify or accelerate development.

## Required pre-implementation record

Create a feature security note in the issue, design document, or pull request before implementation. It must answer each item below. Mark an item **not applicable** only with a brief reason.

1. **Security risks:** Identify assets, threat actors, abuse cases, trust assumptions, failure modes, and likely impact. Consider account takeover, broken object-level authorization, replay/duplication, race conditions, provider compromise/outage, chain reorganization, insider misuse, data exposure, and denial of service where relevant.
2. **Data and boundaries:** Identify personal, authentication, financial, ledger, transaction, audit, and provider data involved; classify sensitivity; show which client, service, database, queue, custody-provider, chain-provider, and staff boundaries the data crosses. State what must never enter logs, analytics, client bundles, or ordinary storage.
3. **Authentication and authorization:** Specify required customer/staff authentication, MFA or step-up checks, session requirements, resource-level ownership checks, role permissions, approval separation, and denied actions. Authentication does not replace authorization.
4. **Validation and audit:** Specify server-side input validation, output/error handling, network/asset identity validation, idempotency/replay controls, state-transition constraints, rate limiting, and the audit events required. Define sensitive-field redaction and avoid logging credentials or signing secrets.
5. **Security tests, written first:** Add relevant security-focused tests before the feature implementation. Cover both allowed and denied paths. Select applicable cases from the examples below and add feature-specific abuse cases. Tests must assert the security property, not only a successful response.
6. **Unresolved concerns:** List open assumptions, provider or standards dependencies, operational/legal/security questions, owner, and release impact. Do not hide unresolved concerns in code comments or defer them without an explicit disposition.

## Security test selection guide

Select tests that match the feature's data and boundaries. Typical cases include:

- Unauthenticated request rejected; invalid/expired/revoked session rejected.
- Customer A cannot read or mutate Customer B's wallet, asset, transaction, or support case.
- Staff roles cannot access actions outside their permission; support cannot invoke custody operations; maker cannot be sole approver.
- Invalid, malformed, oversized, unsupported, or inconsistent input is rejected without leaking internal details.
- Duplicate request, idempotency-key reuse, webhook replay, duplicate provider event, and queue redelivery do not create duplicate financial effects.
- Concurrent operations cannot overspend, double-reserve, double-credit, or break ledger balance invariants.
- Invalid signatures, wrong network identities, unapproved assets, and insufficient confirmation/finality do not post customer credit.
- Uncertain provider responses do not trigger blind resubmission or incorrectly report completion.
- Audit records are created for required state changes and privileged actions, while secrets and sensitive authentication data remain redacted.
- Error, outage, and recovery paths preserve authorization, ledger integrity, auditability, and customer-visible transaction state.

## Implementation and release rules

- Security tests are authored before feature code and remain in the appropriate automated test suite. Do not replace a failing security test with a weaker assertion or skip to make the feature pass.
- Use provider and chain fakes/mocks in ordinary development. Never use production custody credentials or real customer assets in development or tests.
- Financial effects require database-enforced idempotency, balanced journal entries, explicit transaction states, and reconciliation hooks as applicable.
- Treat provider and blockchain events as untrusted input. Verify origin, network/asset identity, uniqueness, state, and finality before ledger effects.
- Keep secrets in approved secrets infrastructure. Do not place credentials, private keys, recovery secrets, tokens, or sensitive payloads in code, clients, fixtures, logs, or analytics.
- If requested behavior conflicts with these requirements or the custody architecture, stop before implementation, explain the conflict, and propose a safer design.
- Do not enable live customer custody, real-money transfers, or public financial operations until the professional authorization, independent security review, operational readiness, and release approvals defined in `NUUR_WALLET_ARCHITECTURE.md` are evidenced.

## Feature completion checklist

- [ ] Pre-implementation security note covers risks and affected assets.
- [ ] Data classification and system/trust boundaries are documented.
- [ ] Customer/staff authentication, authorization, and approvals are specified.
- [ ] Validation, abuse controls, idempotency, and audit requirements are specified.
- [ ] Relevant security tests were written before feature code and assert denied as well as allowed paths.
- [ ] Unresolved concerns have an owner and explicit release disposition.
- [ ] No requirement was weakened, removed, or bypassed.
- [ ] No production financial operation was enabled without all required approvals.
