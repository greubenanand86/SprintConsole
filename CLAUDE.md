# SprintOps Console

React 18 sprint management tool. No build step — Babel transpiles JSX in-browser. UMD bundles in `vendor/`.

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

| Priority | Engineering Constitution | Product Constitution |
|---|---|---|
| 1 | Security | User trust |
| 2 | Stability | Accessibility |
| 3 | User experience | Stability |
| 4 | Maintainability | Simplicity |
| 5 | Performance | Maintainability |
| 6 | Development speed | Speed of delivery |
| 7 | — | Feature expansion |

## Governance

- AI agents may not deploy to production without human approval (Engineering §9 / AI Governance §3)
- Security-sensitive changes require Security Agent review before production
- All significant decisions recorded in `PRODUCT_MEMORY.md`
- Technical debt tracked in Jira (Engineering §12)

## Known Tech Debt

- No TypeScript (Engineering Constitution §2 mandates it — migration is a backlog item)
- No automated test suite (Engineering Constitution §6 mandates unit + integration tests)
- No structured logging library (Engineering Constitution §7)
- No CI pipeline (Engineering Constitution §8)

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

### AI Agent Permissions (§10)

Agents **may**: create stories, refine AC, add UX/QA notes, link dependencies, update statuses, generate release notes, detect stale tickets, summarize blockers, file §8-compliant bugs.

Agents **may NOT**: skip QA, skip Product Acceptance, override release gates, close unresolved production bugs, reprioritize roadmap autonomously, bypass governance.
