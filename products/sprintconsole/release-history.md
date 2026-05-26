# Release History — SprintConsole

> One entry per release. Most recent first. Automated release notes from the Release Risk Agent go here when `JIRA_WRITE_ENABLED=true`.

---

## v0.1.0 — Prototype (2024)

**Type**: Initial prototype
**Status**: Stable

**Summary**: Babel/JSX prototype shipped with four core pages — Readiness Tracker, Estimation Planner, Release Readiness, and Configuration. No backend, no TypeScript, mock data only.

**Shipped**:
- Readiness Tracker (`sprintops-readiness.jsx`)
- Estimation Planner (`sprintops-estimation.jsx`)
- Release Readiness page (`sprintops-release.jsx`)
- Configuration page (`sprintops-config.jsx`)
- Shared component library (`sprintops-shared.jsx`)
- Design token system (`colors_and_type.css`)

**Known limitations at release**:
- No TypeScript
- No build step (Babel in-browser)
- No backend (mock data via `window.SPRINTOPS_DATA`)
- No automated tests
- No CI pipeline
- No mobile client

**Rollback**: N/A (prototype, no production deployment)

**Monitoring window**: N/A

---

## Release entry format (for future releases)

```
## v{semver} — {title} ({date})

**Type**: Feature / Bugfix / Hotfix / Patch
**Status**: Released | Monitoring | Stable | Rolled Back

**Summary**: One paragraph.

**Shipped**:
- Item
- Item

**Jira stories**: SC-NNN, SC-NNN

**Breaking changes**: None / list them

**Rollback plan**: {procedure or "See release-management-playbook.md §rollback"}

**Monitoring window**: {start} → {end}

**Incidents**: None / link to incident postmortem in product-memory/
```
