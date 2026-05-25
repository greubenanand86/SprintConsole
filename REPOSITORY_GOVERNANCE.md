# Repository Governance
## Version 1.0

## Recommended Structure

```text
/repo
  /apps
    /web
    /mobile
  /packages
    /ui
    /api-client
    /validation
    /utils
    /config
  /backend
  /governance
  /docs
```

## Branching Strategy

```text
main        -> production-ready
develop     -> integration
feature/*   -> feature work
bugfix/*    -> bug fixes
hotfix/*    -> urgent production fixes
release/*   -> release preparation
```

## PR Rules

Every PR must include:

- Jira ticket
- Summary
- What changed
- Screenshots/videos if UI
- Test evidence
- Risk notes
- Rollback notes

## Merge Policy

Required before merge:

- CI passes
- Code review completed
- QA path identified
- No unresolved release blockers

## Final Principle

Repository structure should make ownership, reuse, and release safety obvious.
