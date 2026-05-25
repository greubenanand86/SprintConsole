# Product Memory
## SprintOps Console — Decisions, Learnings, and Governance Records

---

## Architecture Decision — 2026-05-25

### ADR-001: Architecture Blueprint v1.0 Adopted

**Decision:** Architecture Blueprint v1.0 is the governing technical standard for all SprintOps Console development, present and future. Full document in `ARCHITECTURE.md`.

**Rationale:** The product is evolving beyond a single no-build Babel prototype toward a multi-client (web + mobile), API-first system. The blueprint establishes consistent, boring-but-scalable defaults so the team doesn't relitigate stack choices story by story.

**Key mandates:**
- Web: React + TypeScript + Next.js (preferred) + React Query + Zustand/Redux Toolkit
- Mobile: React Native + Expo + TypeScript + shared design system
- Backend: API-first, version-aware, centralized auth, validation layer, structured logging
- All clients interact through consistent API contracts — no client-side business logic that leaks platform concerns
- TypeScript is mandatory everywhere (currently a known debt item on web — migration required)
- Feature-based folder organization across all clients

**Technical Decision Hierarchy (ARCHITECTURE.md §15):**
1. Security
2. Stability
3. Maintainability
4. Scalability
5. Developer productivity
6. Performance optimization
7. Architectural sophistication

**Current state vs target state:**
- Current: single-page Babel/JSX no-build prototype (`index.html` + `*.jsx` files)
- Target: `/web` (Next.js/TS), `/mobile` (Expo/TS), `/backend` (API-first), `/shared` (business logic + design system)

**Migration path:** No big-bang rewrite. Each new story should move toward the target structure. TypeScript migration is the highest-priority debt item per Engineering Constitution §2 + Architecture Blueprint §3.

**Constraints:**
- Babel in-browser transpilation is a temporary affordance — it must be replaced as part of the Next.js migration
- Native code in mobile requires Architecture review and Release Risk awareness
- Destructive DB migrations require Architecture review, rollback strategy, and human approval

**Known limitations of current architecture:**
- No TypeScript (debt — Engineering Constitution §2)
- No automated test suite (debt — Engineering Constitution §6)
- No CI pipeline (debt — Engineering Constitution §8)
- No structured logging (debt — Engineering Constitution §7)
- No bundler / build step (debt — Architecture Blueprint §3)

**Recorded by:** Architect Agent / Human  
**Governance refs:** Architecture Blueprint v1.0, Engineering Constitution v1.0, Product Constitution v1.0

---

## Architecture Decision — 2026-05-25

### ADR-002: API Contract Standards v1.0 Adopted

**Decision:** API Contract Standards v1.0 is the governing standard for all API design across web, mobile, and backend clients. Full document in `API_CONTRACT_STANDARDS.md`.

**Rationale:** As the product evolves toward an API-first architecture (Architecture Blueprint §5), consistent API contracts prevent frontend/backend/mobile drift and make integrations predictable across all clients.

**Key mandates:**
- All APIs must include: clear endpoint naming, consistent request/response format, validation rules, auth requirement, error format, pagination where needed, version awareness
- Standard error format: `{ "errorCode": "...", "message": "...", "details": {} }`
- Versioned routes: `/api/v1/...`
- Breaking changes require Architecture review, Release Risk review, and a migration plan
- API contracts are shared product infrastructure — not backend implementation details

**Impact on current state:** SprintOps Console prototype has no backend API yet. These standards apply from the first backend story onward and must be enforced by the Architect Agent during refinement.

**Governance refs:** API Contract Standards v1.0, Architecture Blueprint v1.0 §5

---

## Architecture Decision — 2026-05-25

### ADR-003: Shared Package Strategy v1.0 Adopted

**Decision:** Shared Package Strategy v1.0 governs how code is shared across web and mobile clients. Full document in `SHARED_PACKAGE_STRATEGY.md`.

**Rationale:** Without a shared package strategy, React web and React Native mobile will independently re-implement validation, API clients, analytics, and utility logic — creating drift that becomes expensive to fix.

**Package layout:**
- `/packages/ui` — reusable UI primitives (platform-aware)
- `/packages/api-client` — API clients (fetch wrappers, error handling, versioning)
- `/packages/validation` — shared validation schemas (used by both clients and backend)
- `/packages/utils` — common utilities
- `/packages/config` — shared configuration (no production secrets)
- `/packages/analytics` — analytics event helpers and consistent event naming

**Rules:**
- Shared packages must not contain platform-specific logic
- No business logic duplication across clients — extract to shared
- No direct production config in shared code
- Principle: reduce duplication without hiding platform-specific realities

**Impact on current state:** No `/packages` directory exists yet. These standards apply when the first shared package is introduced and must be enforced by the Architect Agent during refinement.

**Governance refs:** Shared Package Strategy v1.0, Architecture Blueprint v1.0 §3 §4

---

## Architecture Decision — 2026-05-25

### ADR-004: Repository Governance v1.0 Adopted

**Decision:** Repository Governance v1.0 is the governing standard for repo structure, branching, PR requirements, and merge policy. Full document in `REPOSITORY_GOVERNANCE.md`.

**Rationale:** As the codebase grows toward a monorepo (web + mobile + backend + shared packages), consistent structure and branch hygiene prevent ownership ambiguity, unsafe merges, and untraceable releases.

**Monorepo structure:**
- `/apps/web` — React web client
- `/apps/mobile` — React Native mobile client
- `/packages/*` — shared packages (ui, api-client, validation, utils, config)
- `/backend` — API-first backend
- `/governance` — governance docs (ARCHITECTURE.md, API_CONTRACT_STANDARDS.md, etc.)
- `/docs` — product and developer documentation

**Branching strategy:**
- `main` → production-ready only
- `develop` → integration branch
- `feature/*` → feature work (branches from develop)
- `bugfix/*` → bug fixes (branches from develop)
- `hotfix/*` → urgent production fixes (branches from main; requires Release Risk review)
- `release/*` → release preparation

**PR requirements (every PR):** Jira ticket, summary, what changed, screenshots/videos if UI, test evidence, risk notes, rollback notes.

**Merge policy:** CI passes + code review completed + QA path identified + no unresolved release blockers.

**Impact on current state:** Current repo has no `/apps` or `/packages` structure. Migration toward the monorepo layout is part of the TypeScript + Next.js migration work.

**Governance refs:** Repository Governance v1.0, Architecture Blueprint v1.0, Jira Workflow Governance v1.1

---

## Release Management — 2026-05-25

### ADR-005: Release Management Playbook v1.0 Adopted

**Decision:** Release Management Playbook v1.0 is the governing standard for all release workflows, deployment governance, rollback expectations, monitoring procedures, mobile release coordination, and production approval requirements. Full document in `RELEASE_MANAGEMENT_PLAYBOOK.md`.

**Rationale:** As the product moves toward multi-client (web + mobile) and multi-environment (dev, staging, QA, production) deployments, consistent release processes prevent deployment chaos, ensure rollback readiness, and enforce human approval gates before production. The playbook establishes that stability > speed.

**Core principle:** Every release must be observable, recoverable, and governable.

**Release types and approvals:**
- Standard Release (planned delivery): TPM + Human approval required
- Hotfix (critical production fix): TPM + Human approval required
- Mobile Beta (TestFlight/Internal Testing): TPM approval required
- Production Mobile Release (App Store/Play Store): Human approval required
- Infrastructure Release (CI/CD/Auth/DB changes): TPM + Security + Human approval required

**Release workflow stages:**
```
Code Complete → Code Review → QA Validation → Product Acceptance
→ Release Risk Review → Human Approval → Production Release → Monitoring → Done
```

**Release readiness checklist (must pass before production deployment):**
1. QA completed and signed off
2. Product Acceptance completed
3. Monitoring enabled
4. Rollback available and tested
5. Release notes prepared
6. Crash reporting enabled (mobile)
7. Analytics events validated
8. Security review completed (if required)
9. Compliance review completed (if required)

**Mobile release governance (mandatory for mobile releases):**
- TestFlight validation required
- Internal testing validation required
- Store metadata review required
- Versioning consistency check required
- Crash-free beta validation required
- Staged rollout preferred (but not required)

**Rollback governance:**
- All releases require: rollback strategy, rollback owner, rollback validation
- Rollback feasibility must be known before release begins
- Rollback notes documented in release comments

**Monitoring window (Released → Monitoring → Stable → Done):**
- Post-release monitoring mandatory for crashes, API failures, auth issues, performance degradation, analytics anomalies
- Stories transition from Released → Monitoring when deployed, then to Stable when monitoring window closes cleanly, then to Done

**Hotfix governance (for urgent production fixes):**
- Hotfixes require: incident classification (P0-P3), rollback awareness, post-release validation, postmortem documentation
- Hotfix branches must branch from `main` and require Release Risk review before merging
- Hotfix escalation to TPM required per Repository Governance hotfix rules

**Impact on current state:** SprintOps Console prototype has no production infrastructure yet (no multiple environments, no mobile builds, no CI/CD pipeline). These standards apply from the first production-bound story onward and govern the Deploy Specialist Agent, Release Risk Agent, Monitoring Agent, and Incident Agent.

**Governance refs:** Release Management Playbook v1.0, Repository Governance v1.0 (hotfix rules), Engineering Constitution §8 §9, Product Constitution §5

---

## Environment Governance — 2026-05-25

### ADR-006: Environment Governance v1.0 Adopted

**Decision:** Environment Governance v1.0 is the governing standard for all environment structure, deployment flow, configuration isolation, access control, and monitoring. Full document in `ENVIRONMENT_GOVERNANCE.md`.

**Rationale:** As SprintOps Console evolves toward multi-environment (local/dev/staging/prod) deployment, consistent environment structure prevents data leakage, enables predictable rollbacks, and reduces release risk. Staging must mirror production to provide production confidence.

**Mandatory environments:**
- Local: developer iteration (mock data only)
- Development: shared integration (sanitized test data)
- Staging: release validation (scrubbed production-like data)
- Production: customer-facing (real customer data only)

**Deployment flow (no skipping stages):**
```
Local → Development → Staging → Production
```

**Key mandates:**
- Separate configs, secrets, and databases per environment
- No production data in lower environments (unless scrubbed)
- No shared secrets across environments
- Staging mirrors production configuration, integrations, monitoring
- Production access restricted; sensitive changes require TPM + Security review + human approval
- Mandatory monitoring in Staging + Production (logging, crash reporting, alerts, analytics)
- Post-release monitoring window per Release Management Playbook §8

**Secrets & Access Control:**
- All secrets via environment variables (never in code)
- Leaked secrets trigger immediate rotation
- Production access audit-logged
- Rotation on schedule (quarterly minimum)

**Test Data Governance:**
- Local: mock/synthetic only
- Development: sanitized test data
- Staging: scrubbed production-like data (structure intact, PII removed)
- Production: real customer data only
- Compliance review required for data migrations (GDPR, PCI-DSS, CCPA)

**Monitoring Requirements:**
- Structured logging (JSON, context-aware)
- Crash reporting (Sentry, similar)
- Real-time alerting (downtime, errors, performance)
- Post-release window (Released → Monitoring → Stable → Done per Playbook §8)

**Impact on current state:** SprintOps Console prototype runs locally only. Environment Governance applies when development branches and staging instances are created. Standard templates needed for: .env configuration per environment, secrets management, database initialization per environment, monitoring setup.

**Governance refs:** Environment Governance v1.0, Release Management Playbook v1.0 §8, Engineering Constitution §7, Product Constitution §5

---

## Security Governance — 2026-05-25

### ADR-007: Security Baseline v1.0 Adopted

**Decision:** Security Baseline v1.0 is the governing standard for authentication, API security, secrets management, mobile security, dependency governance, logging, auditability, and data protection. Full document in `SECURITY_BASELINE.md`.

**Rationale:** As SprintOps Console evolves toward multi-client (web + mobile) and API-first architecture, consistent security standards prevent credential leaks, unauthorized access, and data exposure. Security must be built in from the start, not added at release time.

**Core security principles (all mandatory):**
- Least privilege access (request only minimum permissions needed)
- Secure defaults (deny by default, encrypt sensitive data, no debug modes in production)
- Auditability (all security-relevant actions logged: who, what, when, where, why)
- Environment separation (Dev ≠ Staging ≠ Prod; no cross-environment credential sharing)
- Secret isolation (centralized secret management; no secrets in source code, frontend/mobile, or logs)

**Authentication standards:**
- Token expiration: access tokens short-lived (15-60 min), refresh tokens longer-lived
- Refresh handling: one-time use, tokens rotated on refresh
- RBAC: users have roles, roles grant permissions, checked at API layer
- Secure storage: HTTP-only cookies (web), Keychain/Keystore (mobile)
- Sensitive auth changes require Security Agent review + human approval

**API security standards (per API Contract Standards v1.0):**
- Auth validation: 401 for unauthenticated, 403 for unauthorized
- Input validation: whitelist expected types, parameterize queries, reject oversized inputs
- Rate limiting: prevent abuse, different limits for auth'd vs. unauth'd users
- Structured error handling: standard format, no stack traces or internal details exposed
- Avoid insecure endpoints: no debug endpoints, no auth bypass, CORS carefully configured

**Secrets management:**
- NO secrets in source control, frontend/mobile code, or logs (mandatory)
- Centralized secret store (Vault, AWS Secrets Manager, etc.)
- Rotation on schedule (quarterly minimum) or immediately if leaked
- Audit logs for secret access

**Mobile security standards:**
- Secure token storage: Keychain (iOS), Keystore (Android)
- HTTPS only, TLS 1.2+, certificate pinning recommended
- Minimal permissions, graceful degradation if denied
- Safe deep linking (validate URLs, only public content)
- Obfuscation and binary hardening in production

**Dependency governance:**
- Automated scanning on every commit (npm audit, Snyk, etc.)
- Known vulnerabilities block CI
- High/Critical: fix immediately (same day)
- Medium: fix next release (1-2 weeks)
- Low: regular schedule (quarterly)

**Logging & auditability:**
- Audit logs: authentication, authorization changes, data access, sensitive operations
- Release traceability: version, deployment time, who deployed, environment
- Auth event logging: login success/failure, logout, permission denied, session timeout
- Deployment visibility: start/end times, version, environment, health checks, rollbacks
- Log retention per compliance (1-3 years typical); tamper-proof, access-controlled

**Data protection:**
- Encryption in transit (HTTPS) and at rest (for sensitive data)
- Minimal exposure (only return needed data, sanitize logs)
- Retention policy defined, old data deleted/anonymized
- Access restrictions (only systems/users that need it, audit logs of access)

**Code review security checklist:**
- No secrets in code, input validation, authorization checks, parameterized queries
- No unsafe deserialization, dependency scanning, safe error messages
- Logging of sensitive operations, HTTPS/TLS enforced, encryption for sensitive data

**Mandatory Security Agent review before production deployment:**
- Auth/authz system changes, data access control changes, new sensitive APIs
- New external service integrations, database schema changes for sensitive data
- Secrets/credential rotation, security-critical library updates
- HIGH/CRITICAL vulnerability fixes

**Security incident response:**
- Immediate mitigation, assessment, remediation, user notification, postmortem
- Critical incidents escalate to TPM + Security Agent + human approval

**Final principle:** Security is a product requirement, not a release-phase activity.

**Impact on current state:** SprintOps Console prototype has basic auth scaffolding (window.SPRINTOPS_DATA mock). Baseline applies when backend API, user authentication, and sensitive data handling are implemented.

**Governance refs:** Security Baseline v1.0, Engineering Constitution §4, API Contract Standards v1.0, Environment Governance v1.0, Release Management Playbook §3 §11

---
