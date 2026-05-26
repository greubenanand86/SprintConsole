# Apps

Application code for each product, separated by platform.

## Proposed structure

```
apps/
  sprintconsole/
    web/          ← React + TypeScript + Next.js (target state)
    mobile/       ← React Native + Expo + TypeScript (target state)
  {next-product}/
    web/
    mobile/
```

## Current state

SprintConsole's web app currently lives at the repo root (`sprintops-app.jsx`, `index.html`, etc.). This is the Babel/JSX prototype phase. Migration to `apps/sprintconsole/web/` is planned as part of the TypeScript + Next.js migration (highest-priority tech debt per Engineering Constitution §2 and Architecture Blueprint §3).

## Rules

- Each app directory is self-contained: its own `package.json`, its own build config
- Apps consume shared packages from `/packages` — they do not copy or duplicate shared code
- No business logic in app code: business logic belongs in `/packages`
- Platform-specific code (native modules, web-only APIs) stays inside the platform directory

## Migration note

Do not move code here manually. The migration will happen as a planned sprint, with Architecture Agent review, QA validation, and a staged rollout.
