# Architecture Notes — PTS

> Product-specific decisions only. Shared standards live in `governance/shared/` and take precedence.

## Current state

Greenfield React Native project. Not yet scaffolded. Target is Expo managed workflow with TypeScript from day one.

## Target structure

```
apps/pts/
  mobile/
    App.tsx
    src/
      navigation/     ← React Navigation stack/tab structure
      screens/        ← One file per screen
      components/     ← PTS-specific components
      hooks/          ← Custom hooks
      services/       ← API clients, storage
      types/          ← TypeScript types and interfaces

packages/             ← Shared packages consumed from /packages
  ui/                 ← Shared design system (if extracted)
  api-client/         ← Shared API client (if applicable)
```

## Decisions

### ADR-001 — Expo Managed Workflow (2026-08-16)

**Decision**: Use Expo managed workflow, not bare React Native.
**Why**: Faster iteration, OTA updates, no native build toolchain to maintain in early phase. Ejecting is always available if native module access is needed later.
**Consequence**: Third-party native modules must be Expo-compatible. Any module requiring a bare workflow triggers an Architecture Agent review before adoption.
**Revisit when**: A required native capability is unavailable in managed workflow.

### ADR-002 — TypeScript from day one (2026-08-16)

**Decision**: No JavaScript files. TypeScript strict mode enabled.
**Why**: Shared governance requires TypeScript. Starting TS from day one avoids a migration later. Catches integration errors at build time on a mobile platform where runtime errors are harder to debug.
**Consequence**: All contributors must write TypeScript. No `any` without a documented reason.
**Revisit when**: Never — this is a shared governance requirement.

## Open questions

| Question | Owner | Status |
|---|---|---|
| Backend API — own or consume an existing service? | Architect Agent + human | Open |
| Auth strategy — OAuth, Clerk, custom? | Security Agent + Architect Agent | Open |
| State management — Zustand, Redux, Context? | Architect Agent | Open |
| Navigation library — React Navigation or Expo Router? | Architect Agent | Open |

## Anti-patterns

- No JavaScript files — TypeScript only
- No `any` types without a comment explaining why
- No inline styles — use StyleSheet or a design token system
- No direct API calls in components — use service layer or custom hooks
- No native modules that require ejecting from Expo managed workflow without Architecture Agent sign-off
