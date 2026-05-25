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
