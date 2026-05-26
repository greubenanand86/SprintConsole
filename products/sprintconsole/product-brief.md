# Product Brief — SprintConsole

| Field | Value |
|---|---|
| Product ID | `sprintconsole` |
| Jira project | `SC` |
| Status | Active |
| Owner | greubenanand@gmail.com |
| Phase | Babel/JSX prototype → TypeScript + Next.js + React Native target |

## Problem

Sprint teams lack a single lightweight tool for managing story readiness, estimation, release gates, and sprint health in one place. Existing tools are either too heavy (full PM suites) or too thin (spreadsheets) to support the release discipline a multi-platform product org requires.

## Users

| Role | What they need |
|---|---|
| Engineering Lead / TPM | Sprint health, WIP visibility, release readiness |
| Product Manager | Story readiness, acceptance criteria tracking, sprint scope |
| QA Lead | Release gate status, test coverage, regression risk |
| Developer | Estimation input, story status, blocker visibility |

## Capabilities

| Capability | Status |
|---|---|
| Readiness Tracker | Prototype (`sprintops-readiness.jsx`) |
| Estimation Planner | Prototype (`sprintops-estimation.jsx`) |
| Release Readiness | Prototype (`sprintops-release.jsx`) |
| Configuration | Prototype (`sprintops-config.jsx`) |
| Mobile client | Not started |
| Backend / API | Not started |

## Success metrics

- Sprint readiness rate (% stories meeting DoR at sprint start)
- Estimation accuracy (planned vs actual points across sprints)
- Release gate pass rate (% releases passing readiness check on first attempt)
- Story cycle time (In Development → Done)

## Non-goals

- Jira replacement / full project management
- Time tracking or resource management
- Cross-org portfolio views (Portfolio TPM domain)

## Constraints

- TypeScript migration required before any new major feature investment
- No persistence until backend API milestone — all data is mock/local
- WCAG 2.1 AA minimum on all UI
- Security Baseline v1.0 applies to all platforms
