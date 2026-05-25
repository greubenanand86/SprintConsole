# Security Baseline
## Version 1.0

## 1. Purpose

This baseline defines mandatory security standards across authentication, API design, secrets management, mobile clients, dependency governance, logging, and data protection. Security is a product requirement, not a release-phase activity (§9).

## 2. Core Security Principles

All systems must enforce:

**Least Privilege Access**
- Request only the minimum permissions needed
- Roles and access scoped per user/service
- Regular audits of who has access to what
- Revoke access immediately when no longer needed

**Secure Defaults**
- Deny by default; allow only explicitly needed access
- Encryption by default (in transit and at rest for sensitive data)
- Minimal permissions in deployed environments
- No debug modes or verbose error messages in production

**Auditability**
- All security-relevant actions logged (auth, access, changes)
- Logs include: who, what, when, where, why
- Logs retained per compliance requirements
- Audit trail tamper-proof (cannot be deleted or modified)

**Environment Separation**
- Development ≠ Staging ≠ Production (per Environment Governance v1.0)
- No cross-environment credential sharing
- No production data in development/staging
- Secrets rotated per environment on schedule

**Secret Isolation**
- No secrets in source control (per Environment Governance §11)
- No secrets in frontend/mobile code (ever)
- No secrets in logs (sanitize before logging)
- Centralized secret management (vault, AWS Secrets Manager, similar)

## 3. Authentication Standards

All systems handling authentication must implement:

**Token Standards:**
- Access tokens: short expiration (15-60 minutes recommended)
- Refresh tokens: longer expiration, used to obtain new access tokens
- Token revocation: revoked tokens cannot be used (blacklist or short-lived)
- Token storage: secure storage per platform (HTTP-only cookies preferred for web; Keychain/Keystore for mobile)

**Refresh Token Handling:**
- Refresh tokens rotated on use (one-time use, obtain new on successful refresh)
- Refresh token expiration: longer than access tokens but finite (days/weeks)
- Revoked refresh tokens: user must re-authenticate
- No access token leak from refresh process (refresh tokens not exposed in logs)

**RBAC (Role-Based Access Control) Awareness:**
- Users have roles (user, moderator, admin, custom roles)
- Roles grant permissions (view, edit, delete, approve, etc.)
- Permissions checked at API layer before returning data
- Sensitive data masked or hidden based on user role

**Secure Storage:**
- Web: HTTP-only cookies (not localStorage/sessionStorage for auth tokens)
- Mobile: OS-provided secure storage (Keychain on iOS, Keystore on Android)
- Credentials never logged or exposed in stack traces
- Session invalidation on logout (token revoked, session cleared)

**Sensitive Changes Require Security Review:**
- Auth system changes: Security Agent review before code merge
- Permission system changes: Security Agent review
- Data access control changes: Security Agent review
- After merge: human approval required before production deployment

## 4. API Security Standards

All APIs must enforce:

**Auth Validation (per API Contract Standards v1.0):**
- Every endpoint validates authentication (token present and valid)
- Every endpoint validates authorization (user has permission for the resource)
- Unauthenticated requests: 401 Unauthorized
- Unauthorized requests: 403 Forbidden
- No redirects to login for API clients (return 401/403 status)

**Input Validation:**
- All user inputs validated and sanitized before processing
- Whitelist expected input types and formats (not blacklist bad ones)
- Reject oversized inputs (prevent denial of service)
- Database queries parameterized (prevent SQL injection)
- No `eval()`, `exec()`, or dynamic code execution on user input

**Rate Limiting Awareness:**
- Rate limits enforced to prevent abuse (e.g., 100 requests/minute per IP)
- Rate limit headers returned to client (X-RateLimit-Limit, X-RateLimit-Remaining)
- Exceeded limits: 429 Too Many Requests
- Different limits for authenticated vs. unauthenticated users

**Structured Error Handling:**
- Errors returned in standard format: `{ errorCode, message, details }` (per API Contract Standards)
- Error messages clear and actionable for client (don't expose internal details)
- No stack traces or internal file paths in error messages
- Logging includes full error context (stack trace, context); not exposed to client

**Avoid Insecure Public Endpoints:**
- No endpoints that bypass authentication/authorization
- No debug endpoints in production
- No endpoints that return sensitive data without auth checks
- CORS carefully configured (not `Access-Control-Allow-Origin: *` for sensitive APIs)

## 5. Secrets Management

**Mandatory: No secrets in source control or frontend/mobile code.**

**Secrets Storage:**
- Centralized secret management (Vault, AWS Secrets Manager, Azure Key Vault, etc.)
- Secrets retrieved at runtime from secure store
- Environment variables used to configure access to secret store (not the secrets themselves)
- Secrets never logged; sanitize any values that might leak

**Secrets Rotation:**
- Development secrets: rotated on schedule (quarterly minimum)
- Production secrets: rotated on schedule (quarterly minimum) or immediately if leaked
- Leaked secrets detected: immediate rotation + incident response
- Old secrets retained briefly (72 hours) to allow graceful transition; then deleted

**Frontend/Mobile Security:**
- No API keys embedded in code (hardcoded or in environment files)
- No credentials stored in localStorage, sessionStorage, UserDefaults, SharedPreferences
- OAuth/OIDC preferred for user authentication (delegated to auth service)
- Backend-to-backend authentication via service tokens (never exposed to frontend/mobile)

**Audit Logging of Secret Access:**
- Who accessed which secrets, when
- Changes to secret values logged (not the value itself, just that it changed)
- Audit logs reviewed for unauthorized access

## 6. Mobile Security Standards

Mobile clients (iOS/Android) require additional hardening:

**Secure Token Storage:**
- iOS: Keychain (SecureEnclave preferred)
- Android: Android Keystore
- Never store in UserDefaults, SharedPreferences, or app sandbox
- Automatic lock on device lock (token cleared if device locked for extended period)

**Secure API Communication:**
- HTTPS only (certificate pinning recommended for sensitive APIs)
- No unencrypted HTTP
- TLS 1.2+
- Certificate validation (not accepting self-signed or expired certs)

**Minimal Permissions:**
- Request only required permissions (location, camera, contacts, etc.)
- Explain to user why permission is needed
- Graceful degradation if permission denied
- No requesting all permissions upfront

**Safe Deep Linking:**
- Validate deep link URLs (don't assume they're safe)
- Deep links point to public content only (not user-specific data)
- Deep link handlers validate and sanitize parameters
- No sensitive data in deep link URLs (use tokens/IDs, not PII)

**Obfuscation & Binary Hardening:**
- Production builds obfuscated (code minimization, variable renaming)
- No debug symbols in production builds
- Enable binary hardening (stack canaries, ASLR, DEP/NX)

## 7. Dependency Governance

All projects must maintain dependency security:

**Dependency Scanning:**
- Automated scanning on every commit (CI pipeline)
- Scanning tools: npm audit, OWASP Dependency-Check, Snyk, or similar
- Known vulnerabilities block CI (fail fast)
- Developers notified of vulnerabilities in their PRs

**Vulnerability Awareness:**
- High/Critical vulnerabilities: fix immediately (same day if possible)
- Medium vulnerabilities: fix in next release (1-2 weeks)
- Low vulnerabilities: fix on regular schedule (quarterly)
- Exceptions require Security Agent sign-off

**Outdated Package Monitoring:**
- Major version updates reviewed before upgrading (may introduce breaking changes)
- Security patches applied within 24 hours of release (if not blocked by breaking changes)
- Regular (monthly) dependency updates to stay current

**Vulnerable Dependency Incident Response:**
- Security Agent notified
- Patch or workaround applied
- Deployment expedited if critical
- Postmortem after critical dependency incidents

## 8. Logging & Auditability

All systems must provide audit trails:

**Audit Logs (who, what, when, where, why):**
- User authentication: login success/failure, password change, token refresh
- Authorization changes: role changes, permission grants/revokes
- Data access: who viewed/modified sensitive data (if applicable)
- Sensitive operations: deployments, configuration changes, secrets access
- Errors: all errors logged with context (but not exposed to client)

**Release Traceability:**
- Every release tagged in git with version and timestamp
- Deployment logs record: who deployed, when, to which environment, which version
- Rollbacks logged with reason
- Release notes included in deployment records

**Auth Event Logging:**
- Successful login: user, timestamp, IP, user agent
- Failed login: attempted username, timestamp, IP, reason (invalid password, user not found, account locked)
- Logout: user, timestamp
- Session timeout: user, timestamp
- Permission denied: user, resource, permission, timestamp

**Deployment Visibility:**
- Deployment start/end times logged
- Deployed version recorded
- Deployment target (environment) recorded
- Health checks post-deployment logged
- Rollback decisions and execution logged

**Log Retention & Security:**
- Logs retained per compliance requirements (typically 1-3 years for sensitive systems)
- Logs stored securely (encryption at rest)
- Logs accessible only to authorized personnel (with audit trail)
- Logs tamper-proof (no deletion/modification; append-only)

## 9. Data Protection Standards

Sensitive data requires enhanced protection:

**Encryption Awareness:**
- Data in transit: HTTPS (TLS 1.2+), not HTTP
- Data at rest: encrypted if sensitive (PII, payment info, health data)
- Encryption keys managed separately from data (not stored nearby)
- Key rotation on schedule (quarterly minimum for sensitive data)

**Minimal Exposure:**
- Minimize how many systems have access to sensitive data
- APIs return only data needed for the operation (not all fields)
- Log files sanitized (no PII, payment info, health data in logs)
- Backups encrypted and access-controlled

**Retention Awareness:**
- Data retention policy defined (how long data is kept)
- Old data deleted or anonymized per policy
- User data deletion on request (right to be forgotten)
- Compliance with GDPR/CCPA/HIPAA/PCI-DSS (as applicable)

**Access Restrictions:**
- Sensitive data accessed only by systems/users that need it
- Access logs maintained (who accessed what, when)
- Admin access restricted to security team (with MFA)
- Sensitive data never in public git repos or artifact registries

## 10. Code Review Security Checklist

All code reviews must verify:

- [ ] No secrets in code (API keys, passwords, credentials)
- [ ] Input validation on all user inputs
- [ ] Authorization checks before data access
- [ ] Parameterized queries (no SQL injection risk)
- [ ] No unsafe deserialization (e.g., pickle in Python)
- [ ] Dependencies scanned for vulnerabilities
- [ ] Error messages don't expose internal details
- [ ] Sensitive operations logged (but not exposed to client)
- [ ] HTTPS/TLS enforced (no unencrypted data in transit)
- [ ] Encryption used for sensitive data at rest (where applicable)

## 11. Security Incident Response

Production security incidents require:

1. **Immediate action:** Mitigate the threat (disconnect, revoke credentials, etc.)
2. **Assessment:** Determine scope (affected users, data, systems)
3. **Remediation:** Fix the root cause
4. **Notification:** Inform affected users (if required by law)
5. **Postmortem:** Document root cause, prevention, and lessons learned
6. **Audit trail:** Security incident logged and reviewed

Critical security incidents escalate to TPM + Security Agent + Human Approval per Release Management Playbook §3.

## 12. Security Review Triggers

**Mandatory Security Agent review before production deployment:**
- Changes to authentication/authorization systems
- Changes to data access control
- New API endpoints handling sensitive data
- New integrations with external services
- Database schema changes affecting sensitive data
- Secrets or credential rotation
- Dependency updates to security-critical libraries
- Any HIGH or CRITICAL vulnerability fixes

## 13. Final Principle

Security is a product requirement, not a release-phase activity. Security is built in from the start:
- Design with security in mind
- Implement secure defaults
- Review security in code reviews
- Test security (penetration testing, vulnerability scans)
- Monitor security (audit logs, alerts)
- Respond to incidents quickly
