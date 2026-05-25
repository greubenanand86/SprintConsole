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

## Governance

- AI agents may not deploy to production without human approval (§9)
- Security-sensitive changes require Security Agent review before production
- All significant decisions recorded in `PRODUCT_MEMORY.md`
- Technical debt tracked in Jira (§12)

## Known Tech Debt

- No TypeScript (constitution §2 mandates it — migration is a backlog item)
- No automated test suite (constitution §6 mandates unit + integration tests)
- No structured logging library (constitution §7)
- No CI pipeline (constitution §8)
