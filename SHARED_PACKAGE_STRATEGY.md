# Shared Package Strategy
## Version 1.0

## Purpose

Supports React web + React Native consistency.

## Recommended Shared Packages

```text
/packages/ui
/packages/api-client
/packages/validation
/packages/utils
/packages/config
/packages/analytics
```

## Rules

Shared packages should contain:

- Reusable UI primitives
- API clients
- Validation schemas
- Shared types
- Analytics event helpers
- Common utilities

Avoid:

- Platform-specific logic inside shared packages
- Business logic duplication
- Direct production config in shared code

## Final Principle

Shared packages should reduce duplication without hiding platform-specific realities.
