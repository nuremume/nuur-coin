# NUUR WALLET — Initial Threat Model

**Status:** Design baseline; requires review by named Security, Custody, Operations, Product, and Compliance owners  
**Scope:** Future custodial multi-chain wallet platform and its operational control plane  
**Production status:** No provider is selected and no public financial operation is authorized by this document  
**Companion policy:** [`SECURITY_ENGINEERING_REQUIREMENTS.md`](./SECURITY_ENGINEERING_REQUIREMENTS.md)

## 1. Review boundary

This threat model covers the customer mobile and web clients, separate staff administration app, customer/staff APIs, identity and sessions, wallet and asset registries, internal double-entry ledger, deposit and withdrawal workflows, custody-provider integration, chain/RPC adapters, queues, databases, secrets, audit pipeline, deployment infrastructure, and operations.

The current browser prototype is a simulated UI and has no provider, chain, API, identity, or financial connection. It is not in scope as a live transaction system; its user-facing claims should continue to match the planned custodial model.

This is an initial qualitative analysis. Threat likelihood and residual risk cannot be credibly scored until a custody provider, cloud topology, identity design, operational model, and launch scope are selected. Treat asset movement, ledger corruption, key/provider compromise, cross-customer access, and privileged misuse as **critical impact** risks by default.

## 2. Security objectives and non-negotiable properties

1. NUUR application databases, caches, logs, analytics, and client bundles never contain customer signing keys, seed phrases, or custody-provider signing credentials.
2. Only the custody provider controls customer asset signing infrastructure; NUUR application and support roles cannot bypass provider authorization policy.
3. A customer can access or act on only resources they are authorized to use. Staff permissions are separate, minimal, reviewed, and audited.
4. Every posted financial journal balances per network-specific asset. Posted entries are immutable; corrections are traceable reversals/adjustments.
5. Duplicate API requests, provider webhooks, queue deliveries, chain observations, or retries cannot create duplicate credits, withdrawals, or accounting effects.
6. No blockchain/provider event becomes a customer credit until origin, network, asset, uniqueness, destination, and required confirmation/finality checks pass.
7. An uncertain custody-provider response remains an explicit unknown/reconciling state until verified; it is never blindly resubmitted.
8. Sensitive authentication data, secrets, and unnecessary customer financial/personal details are excluded from logs and analytics.
9. Customer and staff actions that affect access, balances, approvals, transaction states, or configuration are attributable and tamper-evident.
10. Live customer custody and public financial operation remain disabled until all security, custody, operational, and authorization release gates are evidenced.

## 3. Assets and data classification

| Asset/data | Sensitivity / integrity need | Main stores or boundaries | Primary harm if compromised |
| --- | --- | --- | --- |
| Provider credentials and operation authorization | Secret; critical integrity | Managed secret store, custody adapter, provider | Unauthorized signing or provider control |
| Provider-held customer signing material | Highest sensitivity; provider boundary | Custody provider's independently assessed infrastructure | Customer asset theft or loss |
| Password, MFA/passkey/session data | Secret; critical integrity | Identity service, secure client storage for session only | Account takeover, impersonation |
| Customer identity/contact/verification data | Restricted personal data | Identity/account services, approved verification provider if selected | Identity theft, fraud, unauthorized disclosure |
| Customer-to-wallet mapping | Restricted; critical integrity | Wallet service and relational database | Cross-customer exposure or misdirected funds |
| Ledger journals, holds, balances | Financial; critical integrity and availability | PostgreSQL, backups, derived caches | Incorrect liabilities, theft, insolvency/reconciliation failure |
| Withdrawal intents, destination, limits, approval | Financial; critical integrity | Withdrawal service, ledger, queue, provider | Unauthorized or duplicate withdrawal |
| Deposit observations and provider webhooks | External, untrusted input | Webhook intake, event inbox, queue, monitor | False or duplicate customer credits |
| Network and asset registry | Configuration; critical integrity | Approved registry, deployment configuration | Wrong-chain credit, counterfeit asset, bad fee/precision |
| Staff roles, approvals, administrative actions | Restricted; critical integrity | Staff identity, approval service, audit sink | Insider abuse, control bypass, unaccountable actions |
| Audit events, logs, traces, alerts | Security-sensitive; critical integrity | Separate protected logging/audit systems | Undetected or unprovable incident; data leakage |
| RPC credentials, provider API keys | Secret | Managed secrets store and integration workers | Provider abuse, quota exhaustion, data manipulation |
| Queue/outbox/inbox events | Internal financial metadata; integrity critical | PostgreSQL and durable broker | Dropped, duplicated, reordered, or forged effects |
| Backups and disaster-recovery artifacts | Same sensitivity as source data | Encrypted separately controlled storage | Broad data exposure or unrecoverable service |

Data rules: classify fields before adding them, minimize collection, restrict access by service identity, encrypt in transit/at rest, redact logs, and attach retention/deletion rules only after jurisdiction and provider obligations are confirmed.

## 4. Actors, assumptions, and dependencies

### Threat actors

- External attacker using stolen credentials, phishing, malware, automation, or public API abuse.
- Malicious or compromised customer attempting cross-account access, transaction manipulation, or policy evasion.
- Malicious, compromised, or over-privileged employee/contractor, including support or operations staff.
- Compromised customer device, mobile app package, browser session, dependency, CI job, deployment identity, or build artifact.
- Compromised, malfunctioning, misconfigured, or unavailable custody provider, RPC/indexer, webhook sender, cloud service, or notification channel.
- Operator error: wrong network/asset configuration, role assignment, deployment, key rotation, reconciliation, or incident response.
- Chain-level fault: reorganization, delayed finality, inconsistent RPC providers, duplicate observations, malicious token metadata, or unsupported token behavior.

### Assumptions that still need evidence

- Custody provider, HSM/MPC design, provider authorization model, security reports, API specification, webhook specification, contractual responsibilities, recovery/rotation, and exit path are not selected.
- Cloud provider, region, private networking, managed secrets, database, queue, audit sink, and backup architecture are not selected.
- Identity provider, staff directory, MFA/passkey support, recovery workflow, and customer verification model are not selected.
- Ethiopia launch authorization, customer eligibility, financial-crime control requirements, privacy, data residency, retention, and notification duties require qualified local review.
- Network-specific confirmation/finality policies, RPC providers, token identities, NUUR Coin identity/approval, and supported custody assets are not approved.
- Transaction limits, maker-checker policy, support escalation, on-call ownership, reconciliation cadence, RTO/RPO, and customer incident communications are undefined.

If any assumption changes, update this model and associated ADRs before implementing affected features.

## 5. System and trust boundaries

Use the context diagram in [`NUUR_WALLET_ARCHITECTURE.md`](./NUUR_WALLET_ARCHITECTURE.md#3-system-context-and-trust-boundaries). The key boundaries are:

1. **Client to customer API:** all client input and cached client state can be modified by an attacker. Enforce server-side validation and resource authorization.
2. **Customer plane to staff plane:** separate identity realm, entry point, roles, and approval workflow. Customer sessions must not confer staff access.
3. **Application to database/cache/queue:** use workload identities and module-scoped permissions. Redis and queues cannot become balance or approval authorities.
4. **Application to custody provider:** outbound authenticated API boundary; provider's signing system remains outside NUUR's application trust domain.
5. **Custody provider to webhook intake:** inbound untrusted network boundary; verify signatures, freshness/replay protection, schema, event IDs, and state.
6. **Blockchain/RPC to chain adapters:** external observations can be stale, inconsistent, duplicated, or wrong-network. Independently validate canonical network and approved asset identity.
7. **Services to logs/audit/analytics:** data crosses a high-value observation boundary; strict redaction and separate access/retention controls are required.
8. **Build/deploy to production:** repository, dependencies, artifact registry, CI/CD identity, and infrastructure changes can change the effective trust boundary.

## 6. Threat register

The controls below are design requirements, not proof of mitigation. Every row needs feature-specific security tests and evidence before production.

| ID / threat | Boundary and affected data | Required preventive controls | Detection / audit | Required security test themes | Residual/open concern |
| --- | --- | --- | --- | --- | --- |
| T01 Account takeover through credential theft, MFA fatigue, weak recovery, session theft, or enumeration | Client ↔ identity API; credentials, contact data, sessions, wallet mapping | MFA/passkeys where practical, secure recovery, short-lived access tokens, protected/revocable refresh sessions, login throttling, risk/device monitoring, generic public responses, step-up for sensitive changes | Login success/failure, factor changes, recovery, device/session changes, revocations, risk decisions; alerts for unusual patterns | Expired/revoked session rejection; rate limits; generic recovery response; recovery abuse and factor-reset authorization; stolen session revocation | Identity provider and support recovery policy not selected; recovery is high impact and needs abuse review |
| T02 Broken object/function/property authorization (BOLA/BFLA) | Client ↔ customer API; customer, wallet, transaction, verification fields | Server derives customer identity from session; resource ownership check at every read/write; field allowlists; separate staff roles and functions; deny by default | Authorization denials and privileged reads/writes with actor/resource/correlation ID | Customer A cannot enumerate/read/mutate B; mass assignment blocked; customer token cannot call admin route; support cannot call custody operation | Endpoint inventory and route-to-permission matrix required before API launch |
| T03 Malicious or compromised staff misuses admin, approval, or support tools | Staff app ↔ staff API ↔ ledger/custody; roles, destination, approvals, balances | Separate staff realm, phishing-resistant MFA, least privilege, maker-checker, no self-approval, support redaction, custody authorization separated from ordinary admin | Tamper-evident actor/action/target/reason/approval records; alerts for privileged access and role changes; periodic access review | Role matrix denies prohibited actions; requester cannot be sole approver; role revocation takes effect; audit record on every sensitive action | Staff roles, emergency access and independent approver policy require named owners |
| T04 Custody credential theft, application bypass, provider compromise, or provider insider misuse | NUUR worker ↔ custody provider; provider credentials, operation refs, customer asset control | Managed secret store/workload identity, narrow credential scope, provider transaction policies and independent approvals, no signing secret in app/database/client, separation of duties, provider due diligence and exit plan | Credential access, provider operation references, approvals, unusual operation patterns, provider alerts; no secret values in logs | No credential in client artifacts/logs/db; unauthorized operation denied by adapter/policy; approval policy enforced; credential rotation and revocation procedure exercised | No provider selected; HSM/MPC, insurance, controls, contractual split, and incident notification obligations unresolved |
| T05 Forged, replayed, duplicated, delayed, or reordered provider webhook | Provider → webhook/API/queue/ledger; event payload, deposits, withdrawals | Documented signature verification, freshness/replay window, canonical event ID uniqueness, inbox deduplication, schema validation, transactional outbox, monotonic state transitions | Invalid signature/replay/duplicate counters, provider event state, queue lag, event transition audit | Invalid signature rejected; duplicate/replay has one effect; stale event cannot revert state; queue redelivery is idempotent | Exact signing format, key rotation, timestamp window, and provider retry semantics await provider selection |
| T06 False/duplicate deposit credit from wrong network, unapproved asset, premature finality, reorg, or inconsistent RPC | RPC/provider event → registry → deposit monitor → ledger; network/asset/event/ledger | Network-specific approved asset registry, canonical event identity, independent network identity check, confirmation/finality policy, pending vs available states, reconciliation, reversible pending state until finality | Confirmation depth, provider/chain comparison, duplicate event and discrepancy alerts, state transition audit | Wrong chain/contract/mint, unapproved token, duplicate tx/log, unconfirmed event, reorg, conflicting RPC responses never credit twice or prematurely | Each network's finality semantics and independent data source are not approved; Solana/EVM event identity must be specified per adapter |
| T07 Duplicate, race-condition, or replayed withdrawal; available-balance race or double spend | Customer API → withdrawal → ledger → queue → provider; idempotency key, amount, destination, hold, provider ref | Idempotency stored transactionally; atomic balance reservation/hold; unique operation identifiers; DB constraints; policy checks on canonical values; explicit state machine; provider reconciliation before retry | Each request and transition, idempotency conflict, reservation, provider ref, approval, release; invariant/discrepancy alerts | Same key/same request returns original; same key/different request conflicts; parallel withdrawals cannot exceed available balance; queue retries do not resubmit; state transitions reject illegal paths | Exact transaction limits, fee/hold rules, withdrawal approval threshold and provider semantics unresolved |
| T08 Destination, amount, asset, network, or fee altered between review, approval, and provider submission | Client ↔ API ↔ approval ↔ custody; destination, amount, asset/network, fee quote | Server creates immutable intent snapshot; bind approval to exact intent hash/details; step-up auth; validate destination/network/asset and canonical units; revalidate limits at execution; provider policy | Record reviewed fields/version, approver, policy version, final provider request and response reference | Modify client payload after review; stale approval; destination substitution; unsupported asset/network; fee above approved bound; duplicate submit | Address allowlist/risk controls and fee policy require product and compliance decisions |
| T09 Uncertain provider timeout treated as failure/success and blindly resubmitted | Worker ↔ provider ↔ chain ↔ customer history/ledger; provider refs, request state, holds | Idempotent provider request where supported; distinct `unknown/reconciling` state; query by durable client/provider reference; keep hold until reconciled; no blind retries | Age of unknown operations, provider query failures, reconciliation cases and customer status changes | Simulate timeout before/after provider acceptance; confirm no duplicate external operation and no premature release/confirmation | Provider idempotency/query guarantees and outage procedures need contract and sandbox verification |
| T10 Ledger tampering, unbalanced posting, double credit/debit, unsafe repair | API/workers/admin ↔ ledger/database; journal entries, holds, balances | Append-only posted entries; per-asset balance constraints; transactionally balanced journals; immutable posted rows; reversal/adjustment only with reason/approval; DB least privilege; derived balances | Ledger invariant checks, reconciliation, access/change audit, integrity alerts | Property tests for balanced postings; concurrent mutation; rollback on partial write; direct update/delete denied; reversal preserves audit chain | Accounting owner must approve account taxonomy, suspense handling, rounding, fee and reversal rules |
| T11 Sensitive data, credentials, or provider details leak through logs, traces, backups, analytics, notifications, or support screens | Service → observability/backup/client/support; PII, tokens, financial details, secrets | Data minimization, structured redaction, no secret payload logging, restricted and encrypted logs/backups, lock-screen notification minimization, support field redaction, retention/access policies | Redaction health checks, audit of log/backup access, DLP/secret scanning and alerts | Seed test secrets/PII and assert no appearance in logs/errors/analytics; support role sees only allowed fields; backup access controlled | Retention, residency, notification detail, and support visibility depend on legal/provider review |
| T12 Database, Redis, queue, backup, or cloud identity compromise | Workload ↔ data/infrastructure; all records, sessions, events, secrets refs | Private networking, workload identities, least-privilege DB roles, encryption at rest/in transit, separate environments, restricted backups, managed secrets, restore exercises | Cloud audit, network egress, anomalous query/access, backup restore and service alerts | DB role cannot access unrelated module data; dev credential cannot access production; unauthorized backup restore denied; Redis loss cannot alter balance truth | Cloud/region, RTO/RPO, tenant segmentation, encryption key ownership unresolved |
| T13 Malicious dependency, CI/CD compromise, or unauthorized production deployment | Source/dependency/build/deploy → app and infra; code, artifacts, deployment credentials | Protected reviews, least-privilege deployment identities, dependency/SBOM scanning, pinned/reviewed changes, artifact provenance, separated prod approvals, secret scanning, IaC review | CI/dependency alerts, artifact/deployment audit, anomalous privilege use | Unapproved workflow cannot deploy; secret scanner blocks credentials; artifact digest/provenance check; known vulnerable dependency policy tested | CI vendor, artifact registry, signing/provenance policy, emergency patch policy unresolved |
| T14 RPC abuse, SSRF, provider data inconsistency, wrong network, or API key exposure | Adapter ↔ chain/provider; API keys, transaction observations, asset identity | Fixed provider origins, no client-supplied arbitrary RPC URL, egress allowlists, timeouts/resource limits, network ID handshake, validate all external response fields, credential scope | Provider health/latency, divergence between independent sources, API key access, SSRF/egress alerts | Arbitrary endpoint/redirect blocked; wrong network response rejected; malformed/oversized response safe; credentials absent from client and logs | Provider set, failover policy, rate limits, independence of sources not selected |
| T15 Denial of service or abuse of sensitive financial flows | Public APIs/webhooks/login/withdrawals and queue; service availability, customer account status | Per-endpoint rate/resource limits, authentication, workflow abuse controls, bounded payloads, queue backpressure, circuit breakers, provider quotas, customer friction/risk escalation | Rate-limit hits, queue depth, latency, provider quota, login and sensitive-flow anomalies | Resource exhaustion limits; unauthenticated expensive requests rejected; queue backpressure does not drop accepted financial event | Numerical limits, SLOs, customer support and incident communications unresolved |
| T16 Asset/network registry poisoning or unauthorized changes | Admin/deployment → network/asset registry; contract/mint IDs, decimals, enabled state | Change-controlled allowlist, independent review/approval, immutable versioned config, disabled-by-default network/asset, canonical IDs, no metadata-driven trust | Registry diff audit, approval record, unexpected config alert | Unauthorized asset enable rejected; decimals/network mismatch blocked; config rollback audited; stale client cache cannot authorize transaction | Exact approved asset inventory including NUUR Coin is undecided and requires identity/approval gate |
| T17 Account recovery/social engineering and notification interception | Customer support/identity/notification; PII, recovery case, sessions, device data | Verified recovery policy, cooling/step-up controls as decided, no support credential collection, notify old/new channels, session revocation, independent approval for high-risk changes | Recovery request, evidence/decision, factor/session changes, notifications and support access audited | Recovery cannot bypass factors/authorization; old sessions revoked; support cannot mark own case approved; enumeration prevented | Identity proofing and recovery evidence are jurisdiction/provider dependent and unresolved |
| T18 Reconciliation or incident response fails to contain discrepancies | Ledger/provider/chain/ops; assets, liabilities, audit evidence, customer status | Scheduled and event-driven reconciliation, segregated correction path, playbooks, stop controls, restore drills, known incident ownership and escalation | Difference thresholds, age of discrepancy, failed restore/drill, incident audit evidence | Inject provider/ledger mismatch; alert and case created; repair requires approved compensating journal; restore meets approved objective | Reconciliation cadence, stop authority, RTO/RPO, customer/regulatory notification process unresolved |

## 7. Security test plan before implementation

Tests are requirements for future implementation, not claims that tests have run. Write the relevant tests before each feature's production code as required by [`SECURITY_ENGINEERING_REQUIREMENTS.md`](./SECURITY_ENGINEERING_REQUIREMENTS.md). The first nonproduction backend must include at minimum:

### Identity and authorization

- `customer_cannot_read_or_mutate_another_customers_wallet`
- `customer_access_token_cannot_call_staff_routes`
- `support_role_cannot_create_or_approve_custody_operation`
- `maker_cannot_be_sole_approver_for_sensitive_operation`
- `revoked_or_expired_session_is_rejected`
- `recovery_and_login_responses_do_not_enumerate_accounts`

### Ledger and withdrawal correctness

- `every_posted_journal_balances_per_asset_network`
- `posted_journal_cannot_be_updated_or_deleted`
- `parallel_withdrawals_cannot_overdraw_available_balance`
- `same_idempotency_key_same_payload_creates_one_request`
- `same_idempotency_key_different_payload_is_rejected`
- `duplicate_queue_delivery_does_not_repeat_provider_submission`
- `provider_timeout_keeps_request_unknown_until_reconciled`
- `approval_is_bound_to_exact_network_asset_destination_amount_and_fee_policy`

### Deposits and external events

- `invalid_provider_signature_is_rejected`
- `duplicate_or_replayed_provider_event_has_one_effect`
- `wrong_network_or_unapproved_asset_event_is_not_credited`
- `unconfirmed_event_is_not_spendable`
- `reorganization_or_conflicting_observation_does_not_double_credit`
- `stale_event_cannot_move_transaction_to_an_invalid_prior_state`

### Data protection and operations

- `secrets_and_authentication_data_are_redacted_from_logs_and_errors`
- `development_identity_cannot_access_production_secrets_or_data`
- `direct_database_role_cannot_modify_posted_ledger_entries`
- `admin_permission_change_is_audited_and_requires_authorized_actor`
- `ledger_provider_discrepancy_creates_alert_and_case_without_silent_repair`
- `restore_and_incident_exercise_meets_approved_recovery_objectives` (exercise evidence, not just a unit test)

Use unit/property tests for invariants, integration tests against disposable PostgreSQL and queue/provider fakes, API authorization tests, and controlled security testing in nonproduction. Production-provider and chain-specific tests require selected providers and an approved test environment. Independent penetration testing remains a launch gate.

## 8. Authentication, authorization, validation, and audit requirements

### Authentication/authorization

- Customer and staff authentication are separate trust domains. Use MFA and phishing-resistant factors where practical; privileged staff require strong authentication.
- Every API endpoint has an explicit access policy. Every customer resource request checks ownership server-side. Staff policy checks both role and action-specific approval requirements.
- Step-up authentication is required for sensitive account changes and risk-selected withdrawals; exact triggers are pending policy decisions.
- Public login/recovery responses are generic. Rate limit by account/device/network risk without providing an enumeration oracle.

### Validation and idempotency

- Validate request schema, size, format, canonical numeric units, network identity, asset registry approval, transaction state, available balance, limits, and destination policy on the server.
- Bind reviews and approvals to immutable transaction intent fields and a policy/asset/network version. Revalidate immediately before provider submission.
- Require idempotency for financial-operation creation; enforce uniqueness at durable storage. Validate provider signatures and unique provider event IDs before queueing.
- Treat provider/RPC responses as untrusted. Enforce timeout, response-size, redirect, origin, and schema constraints.

### Audit and observability

- Audit login/recovery/factor/session events, authorization denials, staff reads/actions, role changes, policy/config changes, approval decisions, ledger posts/reversals, transaction state transitions, provider references, webhook verification outcomes, reconciliation findings, and incident actions.
- Capture actor, action, target, result, reason/approval reference, timestamp, correlation ID, relevant version, and provider operation reference, while excluding secrets and unnecessary payloads.
- Audit writes are protected from ordinary application/admin modification and have monitored retention/access policies.

## 9. Risk disposition and release blockers

All risks in section 6 are open until controls are implemented and evidence is reviewed. These issues block live operations:

1. Custody provider and its security/contractual/control model are not selected or assessed.
2. Legal and regulatory authorization for the intended Ethiopia business and operating model is unconfirmed.
3. Customer/staff identity, recovery, roles, approvals, and separation-of-duty policies are not approved.
4. No ledger, transaction state machine, idempotency implementation, or reconciliation evidence exists in the current prototype.
5. Network/asset identities, confirmation/finality rules, and provider source independence are not approved.
6. Cloud, secrets, queue, audit store, backup/DR, monitoring, response ownership, and recovery objectives are not implemented or tested.
7. No independent security review or penetration test has been completed for a production platform.

The current prototype cannot process deposits or withdrawals. Do not attach live secrets or customer assets to it.

## 10. Reference baselines

Use versioned verification references in security plans and test evidence. OWASP describes [ASVS 5.0.0](https://asvs.owasp.org/) as a requirements framework for web applications and services. The [OWASP API Security Top 10 2023](https://api-security.owasp.org/editions/2023/en/0x11-t10/) specifically includes object-level authorization, authentication, sensitive business-flow abuse, resource consumption, and unsafe API consumption. OWASP's [MASVS](https://mas.owasp.org/MASVS/02-Frontispiece/) covers mobile client controls; its assessment guidance clarifies that mobile checks do not replace verification of remote endpoints, for which an appropriate server-side standard such as ASVS is needed. [NIST CSF 2.0](https://www.nist.gov/publications/nist-cybersecurity-framework-csf-20) is a risk-management outcome framework, not a prescribed implementation or legal authorization.

These references inform engineering and assessment planning. They do not certify NUUR WALLET or establish the legal requirements for any market.
