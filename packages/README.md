# Packages

Shared code consumed by all apps and products. No product-specific or platform-specific logic.

## Package index (target state)

| Package | Purpose | Consumers |
|---|---|---|
| `ui` | Shared design system components (React + React Native) | All web + mobile apps |
| `api-client` | Typed API client, request/response contracts | All apps |
| `validation` | Shared input validation schemas (Zod/Yup) | All apps + backend |
| `utils` | Date, string, number, and collection utilities | All apps + backend |
| `config` | Environment config loading and feature flags | All apps + backend |
| `analytics` | Shared event definitions and tracking interface | All apps |

## Current state

No shared packages exist yet. Code sharing across web and mobile is a planned investment gated on the TypeScript migration. See `SHARED_PACKAGE_STRATEGY.md` in `governance/shared/` for the full strategy.

## Rules

A package belongs here when:
- Two or more products or platforms would otherwise duplicate the same logic
- The code has no product-specific domain logic
- The code has no platform-specific dependencies (or uses conditional exports to abstract them)

A package does not belong here when:
- It contains business logic specific to one product
- It would couple two products' release cycles
- It is a convenience wrapper that would only ever be used by one consumer

## Structure (per package)

```
packages/{name}/
  src/
    index.ts
  package.json
  tsconfig.json
  README.md       ← what this package provides, what it does not
```

## Adding a new package

1. Confirm it is needed by at least two consumers
2. Get Architecture Agent review (API design, coupling risk)
3. Create package with typed exports from day one (no `any`)
4. Document what the package provides and what it explicitly does not
