# Shared vs Product-Specific Rules

This document defines what belongs in shared governance versus a product workspace. When in doubt, use the tests at the bottom.

---

## Shared governance

Lives in `governance/shared/`. Owned by the shared agent organization and the Portfolio TPM. Applies to every product in this repo without modification.

**Change it when** the rule should change for all products at once.
**Do not change it** to accommodate one product's exception — that exception belongs in the product workspace.

### What belongs here

#### Engineering Constitution
Rules that govern how all code is written: component structure, state management, accessibility requirements, performance constraints, error handling, observability, security practices.

> **Example (shared):** "Every component must handle loading, error, and empty states."
> **Not this (product-specific):** "The Estimation Planner shows a spinner on load." That's implementation detail for `products/sprintconsole/architecture-notes.md`.

#### Product Constitution
Principles that govern how all products are designed and delivered: UX standards, design system rules, delivery gates, analytics expectations, AI agent boundaries.

> **Example (shared):** "Every feature must include loading, empty, error, and offline states."
> **Not this (product-specific):** "SprintConsole's empty state for the Readiness Tracker reads 'No stories in this sprint yet.'" That's UX copy for the product.

#### AI Governance
Rules that govern agent behavior across the entire organization: what agents may and may not do autonomously, escalation protocols, human approval requirements, advisory-first defaults.

> **Example (shared):** "No agent may deploy to production without human approval."
> **Not this (product-specific):** "SprintConsole's Release Risk Agent flags any release with fewer than 3 QA-verified stories." That's a product-level threshold.

#### Agent prompts
The mission, authority, inputs, outputs, and decision criteria for each shared agent role. One prompt per agent, applicable to any product they serve. Lives in `claude/agents/`.

> **Example (shared):** The QA Lead Agent prompt defining how it validates acceptance criteria.
> **Not this (product-specific):** "For SC-412, the QA Lead flagged the estimation flow as failing keyboard navigation." That's a Jira comment, not a prompt change.

#### Security baseline
Authentication standards, secrets management rules, dependency governance, API security requirements, data protection policies, logging and auditability rules.

> **Example (shared):** "No secrets or credentials in source. Use environment variables or a secrets manager."
> **Not this (product-specific):** "SprintConsole's Jira API token is stored in `.env.local`." That's an implementation note for the product's config.

#### Release playbook
Release types, approval gates, readiness checklist, rollback strategy, monitoring window definition, mobile coordination requirements.

> **Example (shared):** "Cannot release unless QA done, Product Acceptance done, rollback available, monitoring ready, release notes finalized."
> **Not this (product-specific):** "SprintConsole v1.2.0 was rolled back on 2025-04-03 due to a broken estimation sync." That's a release history entry for `products/sprintconsole/release-history.md`.

#### Common architecture standards
Monorepo structure, target stack decisions, branching strategy, PR requirements, merge policy, API contract standards, environment governance.

> **Example (shared):** "All web apps target React + TypeScript + Next.js under `apps/{product}/web/`."
> **Not this (product-specific):** "SprintConsole is still in Babel/JSX prototype phase — TypeScript migration is Horizon 2." That's `products/sprintconsole/architecture-notes.md`.

#### Reusable components and packages
UI components, API clients, validation schemas, utilities, config loaders, and analytics interfaces that are used by two or more products. Lives in `packages/`.

> **Example (shared):** `packages/ui/Button` — used by SprintConsole web and mobile.
> **Not this (product-specific):** A `ReadinessTrackerCard` component that only appears in SprintConsole. That stays in the product's source tree until a second product needs it.

---

## Product-specific memory

Lives in `products/{product-id}/`. Owned by that product's team. Applies only to that product.

**Change it freely** — it has no effect on other products.
**Do not put it in shared governance** just because it feels important. Importance doesn't make something shared.

### What belongs here

#### Product roadmap
The aspirational sequence of features, debt work, and milestones for this product. Horizons, dependencies, and scope boundaries.

> **Example:** SprintConsole's Horizon 2 includes the TypeScript migration and CI pipeline. Another product's roadmap is completely separate.

#### Feature decisions
Why a specific feature was built the way it was, what alternatives were considered, what was descoped. Recorded in `product-memory/product-decisions/`.

> **Example:** "We chose a card-based layout for the Readiness Tracker over a table because the card format scales better to mobile — see `2025-03-10-readiness-tracker-layout.md`."

#### Customer context
Who uses this product, what they care about, what they've told the team, what segments or personas the product serves.

> **Example:** "SprintConsole's primary user is the engineering lead / TPM in a 2–10 person product team. They use it during sprint planning and pre-release review, not daily."

#### UX decisions specific to this product
Flow choices, interaction patterns, copy decisions, and accessibility trade-offs that apply only to this product's UI. Recorded in `product-memory/ux-decisions/`.

> **Example:** "The Release Readiness page uses a red/amber/green gate model rather than a checklist because gate status needs to be readable at a glance. See `2025-04-01-release-gate-visual.md`."
> **Not shared:** This doesn't change how other products present release status.

#### Release history
The record of every release for this product: what shipped, what broke, rollback events, monitoring window outcomes.

> **Example:** `products/sprintconsole/release-history.md` records v0.1.0 through current. Another product's releases are in its own release-history file.

#### Product-specific technical debt
Shortcuts taken during delivery, prototype-phase compromises, and known fragilities that are specific to this codebase. Recorded in `product-memory/technical-debt/`.

> **Example:** "SprintConsole uses `window.SPRINTOPS_DATA` as a global mock store. This breaks in any multi-tab or multi-user context and must be replaced when the backend ships. See `2024-11-01-mock-data-global.md`."
> **Not shared:** This is not an org-wide engineering problem — it's a SprintConsole prototype decision.

#### Product-specific architecture notes
ADRs, open questions, anti-patterns, and target structure decisions that only affect this product's codebase.

> **Example:** "SprintConsole will use Next.js App Router (not Pages Router) when it migrates to TypeScript. See ADR-005 in `products/sprintconsole/architecture-notes.md`."
> **Not shared:** This doesn't dictate the stack for other products, which make their own ADRs.

---

## Decision tests

When you're unsure where something belongs, ask:

| Test | If yes → | If no → |
|---|---|---|
| Would this rule change how every product in the repo is built or governed? | Shared | Product-specific |
| Does changing this affect more than one product's release cycle? | Shared | Product-specific |
| Is this a standard that a new product should inherit automatically? | Shared | Product-specific |
| Does this record what happened in one product, not what should happen everywhere? | Product-specific | Consider shared |
| Is this context that only makes sense if you know this product's users or history? | Product-specific | Consider shared |
| Would two products reasonably make different choices here? | Product-specific | Consider shared |

## Conflict rule

If a product-specific decision contradicts shared governance, shared governance wins. The product team must either comply, or raise a governance change request that updates the shared document for everyone — not carve out a silent exception.

> **Example of the wrong approach:** Adding a `dangerouslySetInnerHTML` usage in SprintConsole because "this case is safe" without Security Agent sign-off and a governance note. That's a silent exception.
> **Right approach:** Get Security Agent sign-off, record the rationale in `product-memory/architecture-decisions/`, and reference the Security Baseline clause that was evaluated.
