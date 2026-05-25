# SprintOps Console

React 18 sprint management tool. No build step — Babel transpiles JSX in-browser. UMD bundles in `vendor/`.

> **Architecture Blueprint v1.0** (`ARCHITECTURE.md`) is the governing technical standard.
> **API Contract Standards v1.0** (`API_CONTRACT_STANDARDS.md`) governs all API design — error format, versioning, auth, pagination.
> **Shared Package Strategy v1.0** (`SHARED_PACKAGE_STRATEGY.md`) governs code sharing across web and mobile — `/packages/ui`, `/api-client`, `/validation`, `/utils`, `/config`, `/analytics`.
> **Repository Governance v1.0** (`REPOSITORY_GOVERNANCE.md`) governs monorepo structure, branching (`main/develop/feature/*/bugfix/*/hotfix/*/release/*`), PR requirements, and merge policy.
> **Release Management Playbook v1.0** (`RELEASE_MANAGEMENT_PLAYBOOK.md`) governs release types, approval requirements, readiness checklist, mobile coordination, rollback strategy, and monitoring window (Released → Monitoring → Stable → Done).
> **Environment Governance v1.0** (`ENVIRONMENT_GOVERNANCE.md`) governs environment structure (Local/Development/Staging/Production), deployment flow, configuration isolation, secrets management, test data governance, and monitoring requirements.
> **Security Baseline v1.0** (`SECURITY_BASELINE.md`) governs authentication, API security, secrets management, mobile security, dependency governance, logging, auditability, and data protection — security is a product requirement, not a release-phase activity.
> **Lightweight Legal & Compliance Governance v1.0** (`LEGAL_COMPLIANCE_GOVERNANCE.md`) establishes a Legal & Compliance Agent as a risk-identification layer (not an AI attorney) to flag data privacy, consent, accessibility, student data, credential, third-party SDK, and policy alignment risks early — escalates to human counsel for final decisions.
> **Product Memory System v1.0** (`PRODUCT_MEMORY_SYSTEM.md`) stores durable organizational intelligence (decisions, rationale, learnings, constraints) to prevent architecture drift, repeated mistakes, and lost context — optimize for decision continuity, not documentation volume.
> **Metrics & Operational Dashboard Framework v1.0** (`METRICS_DASHBOARD_FRAMEWORK.md`) defines organizational health, delivery, quality, efficiency, and user impact metrics across 6 dashboards (TPM, Engineering, Product, Operational, AI Governance, custom) — metrics exist to improve decisions, not create pressure.
> **Incident Management Playbook v1.0** (`INCIDENT_MANAGEMENT_PLAYBOOK.md`) governs incident handling, escalation flow, rollback procedures, communication expectations, and postmortem governance — incidents are learning opportunities, not blame exercises.
> Current state is a Babel/JSX prototype. Target state is React+TS (web), React Native+Expo+TS (mobile), API-first backend.
> Every story should move toward the target. TypeScript migration is the highest-priority debt item.

## Stack

- React 18 (UMD via vendor/react.development.js)
- Babel Standalone (in-browser JSX transpilation)
- Lucide icons (UMD via vendor/lucide.min.js)
- Vanilla CSS with design tokens (`colors_and_type.css`)
- No TypeScript (flagged as tech debt — Engineering Constitution §2 mandates TS)
- No bundler, no build step, no npm run dev

## File Map

| File | Purpose |
|---|---|
| `index.html` | Entry point — loads all vendor + app scripts |
| `sprintops-app.jsx` | Root app, tab routing, top-level state |
| `sprintops-shared.jsx` | Shared components: Button, Badge, Card, Modal, StatusIcon |
| `sprintops-layout.jsx` | Shell layout, sidebar nav, header |
| `sprintops-readiness.jsx` | Readiness Tracker page |
| `sprintops-estimation.jsx` | Estimation Planner page |
| `sprintops-release.jsx` | Release Readiness page |
| `sprintops-config.jsx` | Configuration page |
| `sprintops-data.js` | Mock data (`window.SPRINTOPS_DATA`) |
| `colors_and_type.css` | Design tokens: `--color-*`, `--radius-*`, `--space-*`, `--shadow-*` |

## Engineering Rules (Engineering Constitution v1.0)

### Components
- Every component must handle **loading**, **error**, and **empty** states
- No business logic inside UI components
- Use `sprintops-shared.jsx` components — do not duplicate
- Use CSS variables from `colors_and_type.css` — no hardcoded hex values or px magic numbers
- Components must be accessible: semantic HTML, keyboard navigation, ARIA labels

### State
- Local state stays local (`useState`, `useReducer`)
- No global state abuse — pass props or lift state minimally
- Clean up event listeners and timers in `useEffect` return functions

### Performance
- Avoid unnecessary re-renders (stable references, `useMemo`/`useCallback` only when measurably needed)
- Keep components small and focused
- No blocking UI operations

### Accessibility (Mandatory — §5)
- Semantic HTML elements (`button` not `div onClick`)
- Keyboard navigable interactive elements (`tabIndex`, `onKeyDown`)
- ARIA labels on icon-only buttons
- Sufficient contrast (use `--color-text-*` tokens, not muted text for critical info)
- Screen-reader aware state changes

### Security (§4)
- No secrets or credentials in source
- Validate all user inputs before processing
- Use environment variables for configuration
- No `eval()`, no `dangerouslySetInnerHTML` without sanitization

### Observability (§7)
- Wrap component trees in Error Boundaries
- Log errors with structured context (not bare `console.log`)
- Track significant user interactions for analytics
- Provide meaningful empty/error state messages to users

## Product Constitution Principles (v1.0)

### Simplicity First (§1)
If a feature requires extensive explanation, the UX needs improvement. Prefer smaller coherent products over large fragmented ones.

### UX Principles (§2)
Every feature must include: loading states, empty states, error states, offline considerations. Error messages must be clear, suggest recovery, avoid technical jargon, and preserve user progress.

### Design System (§3)
All UI derives from `sprintops-shared.jsx` components and `colors_and_type.css` tokens. No one-off UI patterns. No visual fragmentation.

### Product Governance (§4)
Before building any feature, answer: Who benefits? What problem is solved? Why now? What is the maintenance cost? Does similar functionality already exist?

### Delivery (§5)
A release is not complete without: UX reviewed, QA validated, accessibility checked, rollback available, release notes prepared.

### Analytics (§8)
Every story should identify what metric proves the feature is working.

### AI Agent Boundaries (§9)
AI agents may: suggest improvements, generate UX proposals, identify inconsistencies, automate repetitive work.
AI agents may NOT: autonomously redefine product strategy, bypass governance, introduce uncontrolled complexity, or override release controls.

## Decision Hierarchy

When tradeoffs arise, higher priority wins:

| Priority | Engineering Constitution | Product Constitution | Architecture Blueprint |
|---|---|---|---|
| 1 | Security | User trust | Security |
| 2 | Stability | Accessibility | Stability |
| 3 | User experience | Stability | Maintainability |
| 4 | Maintainability | Simplicity | Scalability |
| 5 | Performance | Maintainability | Developer productivity |
| 6 | Development speed | Speed of delivery | Performance optimization |
| 7 | — | Feature expansion | Architectural sophistication |

Architecture Blueprint hierarchy governs all structural and stack decisions. Engineering and Product Constitution hierarchies govern feature delivery and UX decisions.

## Governance

- AI agents may not deploy to production without human approval (Engineering §9 / AI Governance §3)
- Security-sensitive changes require Security Agent review before production
- All significant decisions recorded in `PRODUCT_MEMORY.md`
- Technical debt tracked in Jira (Engineering §12)

## Known Tech Debt

- **No TypeScript** — Engineering Constitution §2 + Architecture Blueprint §3 mandate it. Highest-priority debt. Target: migrate to Next.js + TypeScript under `/web`.
- **No bundler / build step** — Architecture Blueprint §3 requires Next.js. Current Babel in-browser is a temporary affordance.
- **No mobile client** — Architecture Blueprint §4 mandates React Native + Expo + TypeScript under `/mobile`.
- **No backend** — Architecture Blueprint §5 mandates API-first backend under `/backend`.
- **No automated test suite** — Engineering Constitution §6 mandates unit + integration tests.
- **No structured logging library** — Engineering Constitution §7.
- **No CI pipeline** — Architecture Blueprint §11 + Engineering Constitution §8.

## Jira Workflow Governance v1.1

### Feature Lifecycle (§3)

```
Idea / Request → Triage → Product Discovery → Ready for Refinement
→ Refined → Ready for Development → In Development → Code Review
→ Ready for QA → QA In Progress → Product Acceptance
→ Ready for Release → Released → Monitoring → Done
```

### State Ownership (§4)

| State | Agent |
|---|---|
| Idea / Request, Triage | PM Agent |
| Product Discovery | PM Agent + UX Agent |
| Ready for Refinement → Refined | Architect Agent |
| In Development | Dev work |
| Code Review | Security Agent + Architect Agent |
| Ready for QA → QA In Progress | QA Lead Agent (§8) |
| Product Acceptance | Product Acceptance Agent (§7) |
| Ready for Release | Release Risk Agent (§11) |
| Released → Monitoring → Done | Monitoring Agent (§12) |
| Production incidents | Incident Agent (§15) |

### Definition of Ready (§5)

A story is not ready for development unless it includes:

- Business objective
- Acceptance criteria
- UX expectations
- Edge cases
- Dependencies identified
- API considerations
- QA notes
- Release impact awareness
- Priority assigned

Mandatory: Product review, UX review, and Architecture awareness.

### Definition of Done (§6)

A story is not complete unless:

- Acceptance criteria validated
- Unit testing completed
- QA verified (QA Lead sign-off)
- Accessibility reviewed (§5 pass)
- Regression impact reviewed
- Documentation updated (where applicable)
- Monitoring/logging added (where applicable)
- Release notes prepared
- Product Acceptance completed (§7)
- Product Memory updated (where applicable)

### Sprint Governance (§9 — Suggested Allocation)

| Category | Target |
|---|---|
| Feature work | 50-60% |
| Technical debt | 15-20% |
| Design debt | 10-15% |
| Bugs/support | 15-20% |

### Release Governance (§11)

Cannot release unless: QA done, Product Acceptance done, rollback available, monitoring ready, release notes finalized, Release Risk review completed.

### Incident Governance (§15)

Production incidents require: severity classification (P0-P3), rollback assessment, root cause tracking, postmortem. Learnings stored in `PRODUCT_MEMORY.md`.

### Workflow Priority Hierarchy (§16)

1. Production stability
2. Security/compliance
3. User experience
4. Release quality
5. Maintainability
6. Delivery speed

## Agent Interaction Protocols v1.0

### Standard Handoff Flow

```
PM Agent → Product Governance → UX Agent → Architecture Agent
→ Delivery Coordinator → Dev → Security Agent → QA Agent
→ Product Acceptance → Release Risk Agent → TPM Agent → Human Approval
→ Deploy Specialist → Monitoring Agent
```

### Handoff Packet Format (§2)

Every stage transition writes a `[HANDOFF PACKET]` Jira comment containing:

| Field | Description |
|---|---|
| Objective | What this story achieves |
| Jira | Key + current status |
| Acceptance Criteria | What was validated |
| UX Notes | UX sign-off summary |
| Technical Notes | Architecture decisions |
| Risks | Open risk items |
| Dependencies | Blocking dependencies |
| Open Questions | Unresolved items |
| Expected Output | What the next stage must deliver |

### Escalation Rules (§3)

Escalate to TPM Agent when:
- Agents disagree (conflicting verdicts on same story)
- Scope changes detected
- Delivery risk increases (QA failed ≥2 times)
- QA blocks release
- Security/legal concerns flagged (HIGH risk)
- Architecture conflicts arise

Any agent may call `escalate_to_tpm()` from `jira.sh`.

### Conflict Resolution Order (§4)

1. Security / legal
2. Stability
3. User experience
4. Product value
5. Maintainability
6. Delivery speed

This order is enforced by the TPM Agent when resolving conflicts.

### Communication Rules (§5)

Agents communicate via structured `[AGENT NAME]` comments in Jira. Every comment must:
- Use a labelled prefix (`[ARCHITECT]`, `[QA LEAD]`, `[TPM AGENT]`, etc.)
- State verdicts clearly (✅ / ❌ / ⚠)
- Identify uncertainty explicitly
- Provide a recommended action
- Avoid implementation jargon in user-facing sections

### AI Agent Permissions (§10)

Agents **may**: create stories, refine AC, add UX/QA notes, link dependencies, update statuses, generate release notes, detect stale tickets, summarize blockers, file §8-compliant bugs.

Agents **may NOT**: skip QA, skip Product Acceptance, override release gates, close unresolved production bugs, reprioritize roadmap autonomously, bypass governance.
