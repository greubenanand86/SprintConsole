# Product Brief — SprintConsole

## Product identity

| Field | Value |
|---|---|
| Product ID | `sprintconsole` |
| Jira project | `SC` |
| Status | Active |
| Owner | greubenanand@gmail.com |
| Current phase | Babel/JSX prototype |
| Target phase | React + TypeScript + Next.js (web) + React Native + Expo (mobile) |

## Problem statement

Sprint teams lack a single, lightweight tool for managing readiness, estimation, release gates, and sprint health in one place. Existing tools are either too heavy (full project management suites) or too thin (spreadsheets, ad-hoc dashboards) to support the release discipline a multi-platform product org requires.

## Core value proposition

SprintConsole is the operational hub for a sprint team: track story readiness, run estimation sessions, gate releases, and monitor sprint health — all in one product with shared context across web and mobile.

## Target users

| User | Primary need |
|---|---|
| Engineering Lead / TPM | Sprint health, WIP visibility, release readiness |
| Product Manager | Story readiness, acceptance criteria tracking, sprint scope |
| QA Lead | Release gate status, test coverage, regression risk |
| Developer | Estimation input, story status, blocker visibility |

## Core capabilities

| Capability | Status |
|---|---|
| Readiness Tracker | Prototype (sprintops-readiness.jsx) |
| Estimation Planner | Prototype (sprintops-estimation.jsx) |
| Release Readiness | Prototype (sprintops-release.jsx) |
| Configuration | Prototype (sprintops-config.jsx) |
| Mobile client | Not started |
| Backend / API | Not started |

## Success metrics

- Sprint readiness rate (% stories meeting Definition of Ready at sprint start)
- Estimation accuracy (planned vs actual across sprints)
- Release gate pass rate (% releases passing readiness check on first attempt)
- Time-to-done (average story cycle time from In Development to Done)

## Non-goals

- Full project management (Jira replacement)
- Time tracking or resource management
- Cross-org portfolio visibility (Portfolio TPM domain, not this product)
- HR, performance, or OKR management

## Constraints

- TypeScript migration is required before any new major feature investment
- No backend means no persistence — all data is mock/local until API milestone
- Accessibility: WCAG 2.1 AA minimum on all UI shipped
- Security Baseline v1.0 applies to all platform work
