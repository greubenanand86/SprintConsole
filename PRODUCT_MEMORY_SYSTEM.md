# Product Memory System
## Version 1.0

## 1. Purpose

The Product Memory System stores durable organizational intelligence so agents and humans maintain decision continuity across sprints, releases, and team changes.

It prevents:
- Organizational forgetting (losing context on why a decision was made)
- Architecture drift (re-litigating the same technical decisions sprint after sprint)
- Repeated mistakes (not learning from past rollbacks, incidents, or failed approaches)
- UX inconsistency (re-implementing discarded UI patterns)
- Recurring bugs (re-introducing bugs that were already fixed)
- Lost roadmap rationale (starting initiatives without understanding why they matter)
- Duplicate work (re-building features that already exist in different form)

## 2. What Product Memory Stores

Product Memory captures durable knowledge: decisions, context, rationale, learnings, standards, and constraints.

### Product Decisions
**What:** Why features exist, roadmap priorities, scope decisions, rejected alternatives.

**Examples:**
- "We chose date-picker UX pattern X because Y (accessibility, mobile UX, user testing)"
- "We rejected mobile app for iOS-only initial launch per contract constraint Z"
- "We deprioritized feature X because customer feedback showed Y is higher-impact"
- "Scope reduction: initially wanted A+B+C, shipped A+B first based on rollback risk"

**Format:**
```
## Product Decision: [title]
Decision: [what was decided]
Context: [why this matters]
Rationale: [why this decision over alternatives]
Alternatives considered: [what we rejected and why]
Risks: [known risks with this decision]
Date: [YYYY-MM-DD]
Owner: [who owns this going forward]
Reviewed by: [human sign-off if decision-critical]
```

### UX Decisions
**What:** Workflow rationale, navigation structures, accessibility considerations, mobile-specific behaviors, rejected UI patterns.

**Examples:**
- "Navigation: sidebar on desktop (persistent), hamburger on mobile (space constraints)"
- "Accessibility: all color information duplicated in text/icons (WCAG 2.1 AA compliance)"
- "Mobile: swipe gestures for [X] rejected (accessibility + discoverability risk)"
- "Button placement: moved from bottom to top after mobile testing showed thumb-reach issues"

**Format:**
```
## UX Decision: [title]
Decision: [what was decided]
Rationale: [why this UX over alternatives]
Accessibility impact: [WCAG compliance notes]
Mobile considerations: [platform-specific behaviors]
Testing evidence: [user testing, A/B results]
Owner: [UX designer / PM]
Date: [YYYY-MM-DD]
```

### Architecture Decisions
**What:** API strategies, state management choices, integration rationale, database design, scaling approaches, React Native constraints.

**Examples:**
- "API versioning: /api/v1/... per API Contract Standards to enable breaking changes with client negotiation"
- "State management: Zustand + Redux Toolkit per Architecture Blueprint (simple + scalable)"
- "Database: separate read/write databases for analytics (scaling consideration for large datasets)"
- "React Native: shared validation in /packages/validation (reduce duplication, enforce consistency)"
- "Authentication: OAuth2 with refresh tokens (security + user experience tradeoff)"

**Format:**
```
## Architecture Decision: [title]
Decision: [what was decided]
Context: [what problem this solves]
Rationale: [why this approach over alternatives]
Alternatives considered: [what we rejected and why]
Constraints: [known limits of this decision]
Scaling implications: [how this scales as data/users grow]
Owner: [tech lead / architect]
Date: [YYYY-MM-DD]
Reviewed by: [architecture review notes]
```

### Technical Debt
**What:** Known compromises, temporary workarounds, scaling concerns, deferred refactors.

**Examples:**
- "No TypeScript: using JSX/Babel (temporary affordance per Architecture Blueprint §3; migrate to Next.js/TS)"
- "Hardcoded mock data: sprintops-data.js (replace with backend API when ready)"
- "No CI/CD: manual deployment (implement GitHub Actions per Architecture Blueprint §11)"
- "No test suite: QA only (add Jest + React Testing Library per Engineering Constitution §6)"
- "Logging: console.log only (replace with structured logging per Engineering Constitution §7)"

**Format:**
```
## Technical Debt: [title]
Debt: [what we compromised on]
Reason: [why we accepted the debt]
Impact: [how this limits us now]
Repayment cost: [effort to fix]
Repayment roadmap: [when we plan to fix]
Scaling risk: [what happens if we don't fix by X date/users]
Owner: [who owns the fix]
Date recorded: [YYYY-MM-DD]
```

### Release Learnings
**What:** Deployment issues, rollback decisions, production incidents, recurring bugs, monitoring gaps.

**Examples:**
- "Incident 2026-05-15: Migration caused N+1 queries; blocked release; fixed with database optimization"
- "Rollback learning: always test rollback procedures before release (prevents discovery-time failures)"
- "Monitoring gap: no alerts for failed async jobs; added error tracking, prevented incident"
- "Recurring bug: timezone handling in batch jobs; root cause was not mocking time in tests"

**Format:**
```
## Release Learning: [title]
Event: [what happened — incident, rollback, bug, etc.]
Impact: [severity, duration, affected users]
Root cause: [why it happened]
Fix: [what we did to resolve]
Prevention: [what we'll do to prevent recurrence]
Monitoring: [what we added to catch early]
Owner: [who owns the follow-up]
Date: [YYYY-MM-DD]
```

### Incident Postmortems
**What:** Production incidents, severity (P0-P3), resolution, learnings, prevention actions.

**Examples:**
- "P0 incident 2026-05-15: Auth service down (30 min); root cause was dependency upgrade; fixed with pinned version; added pre-release integration testing"
- "P1 incident 2026-05-20: Data export job failed for >100K users; root cause N+1 queries; fixed with batch query optimization; added load testing"

**Format:**
```
## Incident Postmortem: [title]
Incident: [what went wrong]
Severity: [P0|P1|P2|P3]
Duration: [start-end time, duration]
Impact: [affected users/data/features]
Detection: [how we detected it]
Response time: [how long to resolve]
Resolution: [what we did to fix]
Root cause: [why it happened — system level]
Immediate actions: [patch, workaround, revert]
Short-term fixes: [fix over 1-2 weeks]
Long-term prevention: [architectural improvement]
Owner: [who leads follow-up]
Date: [YYYY-MM-DD]
Reviewed by: [incident commander, tech lead]
```

### Customer Context
**What:** Institution-specific constraints, implementation nuances, contract-sensitive behaviors, integration expectations, pricing/feature boundaries.

**Examples:**
- "Customer X: contract requires FERPA compliance + parent notifications (PPRA) for all student data uses"
- "Customer Y: budget constraint limits us to single-region deployment (no multi-region until contract renewal)"
- "Customer Z: integration requirement: must sync student roster from Google Classroom daily (not real-time)"
- "Feature gate: feature X is enterprise-only per pricing model; gate behind feature flag"

**Format:**
```
## Customer Context: [customer name]
Constraint: [what are we constrained by]
Reason: [why — contract, regulation, architecture, budget]
Impact on development: [what we can/can't do]
Workarounds: [how we handle this]
Owner: [customer success manager / PM]
Date: [YYYY-MM-DD]
Contract ref: [if applicable]
Renewal date: [if time-bounded]
```

### Operational Learnings
**What:** Sprint learnings, workflow failures, governance adjustments, release bottlenecks, team process improvements.

**Examples:**
- "Sprint planning: moved to Thursday (was Tuesday); reduced Thursday blocking and planning lag by 40%"
- "Code review: added security checklist; caught 3 credential leaks before production"
- "QA bottleneck: parallel QA track (previously sequential) reduced time-to-release by 2 days"
- "Release process: added dry-run deployment stage; caught environment config issues before production"

**Format:**
```
## Operational Learning: [title]
Learning: [what we learned]
Context: [what triggered the learning]
Impact: [how it improved (or didn't)]
Action taken: [what we changed]
Results: [measurable improvement, if any]
Owner: [who owns the process]
Date: [YYYY-MM-DD]
Review cycle: [how often we revisit]
```

## 3. Memory Rules

**Only store durable knowledge:**
- Decisions (what was decided and why)
- Rationale (context and alternatives considered)
- Learnings (what we learned and why it matters)
- Standards (how we do things)
- Constraints (what limits us)

**Do NOT store:**
- Temporary conversations (can be retrieved from Jira if needed)
- Random discussions or brainstorming (unless it led to a decision)
- Noisy meeting notes (only the conclusion)
- Low-confidence assumptions (only high-confidence learnings)
- Personal opinions unrelated to decisions (only organizational conclusions)

**Memory is append-only:**
- Never delete past decisions (supersede with new decision if changed)
- Decisions can be revisited, but prior context remains for continuity
- Postmortems are final records; don't edit after fact

## 4. Folder Structure

```text
/product-memory (or PRODUCT_MEMORY.md if single file)
  /product-decisions
    feature-authentication.md
    feature-mobile-app.md
    pricing-tiers.md
    roadmap-2026-H2.md
  /ux-decisions
    navigation-structure.md
    accessibility-wcag-aa.md
    mobile-gestures.md
  /architecture-decisions
    api-versioning-strategy.md
    state-management-zustand.md
    database-read-write-split.md
    monorepo-structure.md
  /technical-debt
    typescript-migration-plan.md
    ci-cd-implementation.md
    test-suite-roadmap.md
  /release-learnings
    incident-2026-05-15-auth-outage.md
    rollback-procedure-update.md
    monitoring-improvements.md
  /incident-postmortems
    postmortem-2026-05-15-P0.md
    postmortem-2026-05-20-P1.md
  /customer-context
    customer-x-ferpa-compliance.md
    customer-y-single-region.md
  /governance-history
    architecture-blueprint-adoption.md
    api-contract-standards-adoption.md
    engineering-constitution-updates.md
```

## 5. Decision Record Format

Every major decision should include:

```markdown
## [Category]: [Decision Title]

**Decision:** [What was decided — short, actionable statement]

**Context:** [Why this decision matters — user impact, business priority, technical constraint]

**Rationale:** [Why this decision over alternatives — benefits, tradeoffs, risk assessment]

**Alternatives Considered:** 
- [Alternative A]: Why we rejected it
- [Alternative B]: Why we rejected it
- [Alternative C]: Why we rejected it

**Risks:** [Known limitations, gotchas, scaling concerns, future implications]

**Owner:** [Who owns this going forward]

**Date:** [YYYY-MM-DD]

**Reviewed by:** [Human sign-off, if decision-critical]

**Review cycle:** [When we revisit this decision — e.g., "end of H1 2026"]

**Impact on:** [What systems/teams this affects]

**Related decisions:** [Links to prior decisions this builds on or supersedes]
```

## 6. Retrieval Rule

**Before proposing major changes, agents must check Product Memory for related decisions.**

- Proposing new API endpoint? Check /architecture-decisions/api-*.md
- Proposing UX change? Check /ux-decisions for prior patterns
- Proposing refactor? Check /technical-debt for deferred decisions
- Proposing feature? Check /product-decisions for scope boundaries

**Agents must cite prior decisions** when relevant:
- "This aligns with API Versioning Decision from 2026-05-01"
- "This supersedes the old nav structure decision from 2025-03-15; here's why"
- "This conflicts with the FERPA constraint documented in Customer Context; needs legal review"

## 7. Memory Maintenance

**Product Memory Agent Responsibilities:**
- Capture decisions and learnings post-release
- Maintain decision currency (note when decisions are superseded)
- Identify gaps (decisions made informally, should be recorded)
- Link related decisions
- Periodically review memory to identify stale/outdated decisions
- Escalate to Product Manager / Tech Lead if decision needs revisiting

**Quarterly Review:**
- Review all decisions > 6 months old
- Identify which still hold true
- Mark superseded decisions clearly
- Update roadmap-related decisions
- Identify emerging patterns that should become standards

## 8. Final Principle

Product Memory should optimize for **decision continuity**, not documentation volume.

- Every decision should have clear rationale that future developers understand
- Every learning should prevent repeating the same mistake
- Every standard should be traceable to a decision or principle
- Every constraint should explain why it exists

Avoid verbose documentation; favor concise, decision-focused records that explain "what" and "why" in a way future team members can understand and build on.
