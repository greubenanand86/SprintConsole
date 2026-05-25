# API Contract Standards
## Version 1.0

## Purpose

Prevents frontend/backend/mobile drift.

## API Rules

All APIs must include:

- Clear endpoint naming
- Consistent request/response format
- Validation rules
- Auth requirement
- Error format
- Pagination where needed
- Version awareness

## Standard Error Format

```json
{
  "errorCode": "RESOURCE_NOT_FOUND",
  "message": "The requested item could not be found.",
  "details": {}
}
```

## API Versioning

Use versioned routes when needed:

```text
/api/v1/...
```

Breaking changes require Architecture review, Release Risk review, and migration plan.

## Final Principle

API contracts are shared product infrastructure, not backend implementation details.
