#!/usr/bin/env bash
# Backend & API Agent — Per Agent Role Specifications v1.0 §16
# Mission: Build secure, consistent, observable backend APIs and business logic
# Authority: Create code and PRs; no destructive DB changes without Architecture+Security+Release Risk+Human approval
# Usage: backend-api-agent.sh [JIRA-KEY]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[ -f "$SCRIPT_DIR/jira.sh" ] && source "$SCRIPT_DIR/jira.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

KEY="${1:-}"

if [ -z "$KEY" ]; then
  # Auto-scan: find API/backend stories in development
  STORIES=$(jira_get "search?jql=project=$JIRA_PROJECT+AND+labels=api+AND+status+in+(%22In+Progress%22,%22In+Development%22)&maxResults=10&fields=summary,status" 2>/dev/null || echo '{"issues":[]}')
  COUNT=$(echo "$STORIES" | jq '.issues | length' 2>/dev/null)
  [ "$COUNT" -eq 0 ] && exit 0

  echo "[BACKEND API] Auto-scan: $COUNT API stories in development"
  echo "$STORIES" | jq -r '.issues[].key' | while read -r K; do
    "$0" "$K"
  done
  exit 0
fi

# Single-story backend review
ISSUE=$(jira_get "issue/$KEY?fields=summary,status,description" 2>/dev/null || echo '{}')
TITLE=$(echo "$ISSUE" | jq -r '.fields.summary // "Unknown"')
STATE=$(echo "$ISSUE" | jq -r '.fields.status.name // "In Progress"')

# Detect API feature categories
IS_CRUD=$(echo "$TITLE" | grep -iE 'create|read|update|delete|crud|list|get|post|put|patch' && echo "yes" || echo "no")
IS_AUTH=$(echo "$TITLE" | grep -iE 'auth|login|logout|token|session|permission|role|oauth' && echo "yes" || echo "no")
IS_MIGRATION=$(echo "$TITLE" | grep -iE 'migration|schema|database|db.*change|alter.*table|add.*column' && echo "yes" || echo "no")
IS_INTEGRATION=$(echo "$TITLE" | grep -iE 'integration|webhook|external|third.party|sdk' && echo "yes" || echo "no")

cat << EOF
[BACKEND API] $KEY — API Implementation Spec

## 1. Backend Summary
- Story: $KEY — $TITLE
- Status: $STATE
- API Categories: $([ "$IS_CRUD" = "yes" ] && echo "CRUD Endpoint" || echo "—")\
$([ "$IS_AUTH" = "yes" ] && echo " Auth/Authz" || echo "")\
$([ "$IS_MIGRATION" = "yes" ] && echo " ⚠️ DB Migration" || echo "")\
$([ "$IS_INTEGRATION" = "yes" ] && echo " External Integration" || echo "")
- Target: /backend (API-first per ARCHITECTURE_BLUEPRINT.md §5)
- Contract: Governed by API_CONTRACT_STANDARDS.md v1.0

## 2. API Changes
Contract requirements (per API_CONTRACT_STANDARDS.md v1.0):

Request format:
  - URL: /api/v1/resource[/id] (versioned prefix mandatory)
  - Method: GET (read), POST (create), PUT (replace), PATCH (partial), DELETE
  - Headers: Authorization: Bearer <token>, Content-Type: application/json

Response format:
  - Success: { "data": {...}, "meta": {"timestamp":...}, "version": "1.0" }
  - Error:   { "error": {"code": "...", "message": "...", "details": [...]} }
  - Status codes: 200 OK, 201 Created, 204 No Content, 400 Validation, 401 Auth, 403 Forbidden, 404 Not Found, 500 Server Error

Changes for this story:
  - Document new endpoints in API_CONTRACT_STANDARDS.md or OpenAPI spec
  - No breaking changes to existing endpoints without versioning (v2)
  - Deprecate old endpoints with sunset header if removing

## 3. Data Model Changes
$(
  if [ "$IS_MIGRATION" = "yes" ]; then
    echo "⚠️ DATABASE MIGRATION DETECTED — REQUIRES HUMAN APPROVAL"
    echo "  Cannot apply destructive DB changes without:"
    echo "  1. [ARCHITECT] structural review"
    echo "  2. [SECURITY] data access control review"
    echo "  3. [RELEASE RISK] rollback assessment"
    echo "  4. Human approval before running in production"
    echo ""
    echo "  Migration checklist:"
    echo "  □ Migration file created (version-numbered)"
    echo "  □ Down migration (rollback) implemented"
    echo "  □ Tested in staging before production"
    echo "  □ Data backfill plan if adding NOT NULL columns"
    echo "  □ Zero-downtime migration strategy confirmed"
  else
    echo "No database schema changes detected."
    echo "  If data model changes are required, document them here."
  fi
)

## 4. Auth/Security Impact
$(
  if [ "$IS_AUTH" = "yes" ]; then
    echo "🔐 AUTH/AUTHZ CHANGES — SECURITY AGENT REVIEW REQUIRED"
    echo "  Before implementation:"
    echo "  □ JWT token validation: expiration, signature, audience"
    echo "  □ RBAC: permissions checked at API layer (not just frontend)"
    echo "  □ Token storage: HTTP-only cookies (web), Keychain/Keystore (mobile)"
    echo "  □ Refresh token rotation implemented"
    echo "  □ Logout invalidates token server-side"
  else
    echo "Standard auth checks:"
  fi
  echo "  - 401 returned for unauthenticated requests"
  echo "  - 403 returned for unauthorized (authenticated but not permitted)"
  echo "  - No secrets or credentials in API responses"
  echo "  - Input validated server-side (whitelist expected types)"
  echo "  - Rate limiting configured for this endpoint"
  echo "  - No stack traces in error responses"
)

## 5. Logging/Monitoring
Structured logging requirements (Engineering Constitution §7):
  - Log format: JSON with { "timestamp", "level", "service", "event", "requestId", "userId" }
  - Sensitive data NEVER logged: passwords, tokens, PII, payment data
  - Audit trail: security-relevant operations logged (auth, permission changes, data access)
  - Error logging: stack trace to log (not response), structured error context
  - Request tracing: request-id header propagated through all service calls

Monitoring:
  - Error rate per endpoint (baseline + alerting threshold)
  - Latency p99 target (establish baseline before release)
  - Auth failure rate (spike = potential brute force)
  - DB query performance (no N+1 queries)

## 6. Tests Added
$(
  echo "Backend test requirements (Engineering Constitution §6):"
  echo "  □ Unit tests: business logic, validation, transformation"
  if [ "$IS_CRUD" = "yes" ]; then
    echo "  □ Integration tests: happy path (success + created + updated + deleted)"
    echo "  □ Integration tests: error cases (400 validation, 401 auth, 403 forbidden, 404 not found)"
  fi
  if [ "$IS_AUTH" = "yes" ]; then
    echo "  □ Auth tests: token valid, expired, tampered, missing"
    echo "  □ RBAC tests: each role tested for expected allow/deny"
  fi
  if [ "$IS_MIGRATION" = "yes" ]; then
    echo "  □ Migration tests: up and down migrations validated"
    echo "  □ Data integrity: no orphaned records, constraints enforced"
  fi
  echo "  □ Contract tests: response structure matches API_CONTRACT_STANDARDS.md"
)

## 7. Migration/Rollback Notes
$(
  if [ "$IS_MIGRATION" = "yes" ]; then
    echo "⚠️ Rollback plan REQUIRED before production deployment"
    echo "  - Down migration script tested in staging"
    echo "  - Point-in-time recovery available (DB backup)"
    echo "  - Traffic can be paused if migration runs long"
    echo "  - Hotfix branch path documented if migration fails"
    echo "  - Release Risk Agent must assess before deploy"
  else
    echo "No DB migrations — standard code rollback applies:"
    echo "  - git revert HEAD"
    echo "  - Redeploy previous build artifact"
  fi
)

## 8. Risks
$(
  echo "Backend risks for this story:"
  [ "$IS_AUTH" = "yes" ] && echo "  - 🔴 HIGH: Auth/Authz changes — security regression risk (Security Agent review mandatory)"
  [ "$IS_MIGRATION" = "yes" ] && echo "  - 🔴 HIGH: DB migration — data loss risk if rollback not prepared"
  [ "$IS_INTEGRATION" = "yes" ] && echo "  - 🟠 MEDIUM: External integration — availability and data format dependency risk"
  echo "  - 🟡 MEDIUM: API contract — any breaking change requires v2 route"
  echo "  - 🟡 MEDIUM: Performance — untested queries may have N+1 or slow scans"
)

PR required after:
  → [ARCHITECT] API design review
  → [SECURITY] auth/data review (if auth or sensitive data)
  → [QA LEAD] API integration tests validated
  → [RELEASE RISK] migration/rollback plan confirmed

---
[Backend & API Agent] — Per Agent Role Specifications v1.0 §16 | API_CONTRACT_STANDARDS v1.0
EOF

jira_comment "$KEY" "[BACKEND API] 📡 API implementation spec prepared.
Contract requirements, security, logging, and rollback guidance documented.
[Backend & API Agent]" 2>/dev/null || true
