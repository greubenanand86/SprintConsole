# Environment Governance
## Version 1.0

## 1. Purpose

This governance standard defines mandatory environment structure, deployment flow, configuration isolation, access control, and monitoring requirements to ensure consistency, prevent data leakage, and reduce release risk.

## 2. Mandatory Environments

| Environment | Status | Purpose |
|---|---|---|
| Local | Mandatory | Developer iteration and testing |
| Development | Mandatory | Shared integration and feature testing |
| Staging | Mandatory | Release validation and production confidence |
| Production | Mandatory | Customer-facing / live system |

Optional (future):
- Preview — pre-release audience testing
- Performance testing — load and stress testing

## 3. Environment Responsibilities

| Environment | Purpose | Access | Data |
|---|---|---|---|
| Local | Developer iteration, local testing | Unrestricted (personal machine) | Mock data only |
| Development | Shared integration, feature branches | Team access | Sanitized test data |
| Staging | Release validation, QA testing, pre-production simulation | QA + PM + Engineering | Sanitized production-like data |
| Production | Customer-facing, live transactions | Restricted (TPM + approval required) | Real customer data |

## 4. Deployment Flow

All code must progress through all environments in order. No skipping stages.

```text
Local → Development → Staging → Production
```

**Stage gating:**
- Local: no gate (developer-only)
- Development: development branch merge + CI pass
- Staging: release candidate validation + QA sign-off
- Production: Release Risk review + human approval (§11 Release Management Playbook)

## 5. Environment Isolation

Mandatory separation for all environments:

**Configuration:**
- Separate config files per environment
- Environment variables scoped per environment
- No hardcoded secrets or environment-specific logic in code

**Secrets & Credentials:**
- No shared API keys, database credentials, or tokens across environments
- Production secrets managed separately from source code
- Development / Staging secrets rotated on schedule
- Leaked secrets trigger immediate credential rotation

**Databases:**
- Separate database instances per environment (at minimum, separate schemas)
- Local development uses mock data only
- Development uses sanitized test data
- Staging uses sanitized production-like data (scrubbed of real customer info)
- Production contains real customer data only

**Integrations:**
- Each environment points to test/sandbox versions of external services (payments, email, analytics)
- Production points to live third-party services
- No environment cross-contamination in integration responses

## 6. Production Governance

Production access is restricted and audited.

**Access Control:**
- Restricted to authorized personnel (TPM, on-call, security)
- All production access requires approval
- All production changes logged and auditable
- Emergency access requires incident response protocol

**Production Changes:**
- Sensitive changes (auth, PII, payments, infrastructure) require TPM awareness
- Security-sensitive changes require Security Agent review before deploy
- All production deployments require human approval (Release Management Playbook §9)
- Rollback available and tested for all production changes

**Monitoring:**
- Mandatory logging, crash reporting, analytics
- Real-time alerting for errors, performance degradation, anomalies
- Post-release monitoring window (Released → Monitoring → Stable → Done)

## 7. Staging Governance

Staging should **mirror production** to provide production confidence.

**Configuration:**
- Same environment variables and config structure as production (minus secrets)
- Same external service integrations (using sandbox/test accounts)
- Same database schema and backup strategies as production
- Same monitoring and logging configuration as production

**Data:**
- Production-like volume and shape (but sanitized)
- No real customer PII, payment info, or sensitive data
- Scrubbed customer emails, names, addresses
- Synthetic transactions that match production patterns

**Purpose:**
- Validate release behavior before production
- Test rollback procedures
- Verify monitoring and alerting
- QA final validation with production-like environment

## 8. Development Governance

Development is a shared integration environment.

**Purpose:**
- Feature branch integration testing
- Cross-feature validation
- Early detection of conflicts and issues

**Data:**
- Sanitized test data
- No production customer data
- Mock / synthetic data for all integrations

**Scope:**
- Feature branches integrate into develop
- CI/CD pipeline runs tests and linting
- Code review completed before merge
- No hotfixes land in development directly (hotfixes go through production first, then cherry-picked to develop)

## 9. Local Development Governance

Local development is developer-owned iteration.

**Data:**
- Mock data only (fixtures, seeds, stubs)
- No real customer data
- No staging or production credentials
- Environment variables configured locally (never committed)

**Testing:**
- Unit tests must pass locally before push
- Integration tests optional (can use local containers)
- No requirement to connect to shared services

## 10. Test Data Governance

Avoid unnecessary production data copies. Protect learner and customer data.

**Rules:**
- Local and Development use **only sanitized / synthetic data**
- Staging may use **scrubbed production-like data** (customer metadata structure but no PII)
- Production contains **real customer data only**
- Never copy production data to lower environments without approval and scrubbing
- Leaked customer data triggers incident response

**Sanitization Requirements:**
- Remove real customer names, emails, addresses, payment info
- Remove personally identifiable information (PII)
- Remove health, financial, or sensitive data
- Keep data structure and volume realistic for testing

**Regulatory Requirements:**
- GDPR: no EU customer data in non-EU environments
- PCI-DSS: no payment card data outside production
- CCPA: no California resident data outside authorized uses
- Compliance review required for data migrations

## 11. Secrets Management

No secrets in source code. All environments use environment variables or secure stores.

**Rules:**
- API keys, database passwords, tokens: **environment variables only**
- `.env` files: **never committed** (add to `.gitignore`)
- Secrets rotation: **on schedule** (quarterly minimum)
- Leaked secrets: **immediate rotation** (incident response)
- Production secrets: **restricted access** (TPM only, audit logged)

## 12. Monitoring Requirements

Mandatory monitoring in Staging and Production.

**Logging:**
- Structured logging (JSON format, not raw text)
- Logs include context (user, request ID, environment)
- Error logs include stack traces and recovery options
- Logs retained per compliance requirements

**Crash Reporting:**
- Crash/error reporting enabled (Sentry, similar)
- Errors grouped and tracked
- P0/P1 errors trigger alerts
- Post-deploy crash monitoring (first 24 hours critical)

**Monitoring & Alerts:**
- Real-time monitoring for response time, error rates, availability
- Alerts for: service down, high error rate, performance degradation
- On-call escalation for critical alerts
- Alert fatigue management (tune thresholds, suppress low-priority)

**Analytics Validation:**
- Event tracking enabled and validated
- Events match expected schema
- No dropped or duplicated events
- Analytics errors caught in monitoring

**Post-Release Window:**
- Release Management Playbook §8: Released → Monitoring → Stable → Done
- First 24 hours: active monitoring, on-call standing by
- Crashes, API failures, auth issues, performance, analytics checked continuously
- If clean, move to Stable; if issues, assess rollback

## 13. Environment Promotion

Code progresses through environments. Promotion gates ensure quality.

**Local → Development:**
- All local tests pass
- Code review approved
- CI pipeline passes
- Merged to develop branch

**Development → Staging:**
- Feature complete (AC met)
- QA validation done
- Code review done
- Feature branch merged to release candidate
- Release notes prepared

**Staging → Production:**
- Release Risk review complete
- Rollback plan documented and tested
- Human approval obtained
- Release window scheduled (off-hours preferred)
- Monitoring team standing by

## 14. Rollback & Recovery

All environments must support rollback.

**Local:**
- Git revert (trivial)

**Development:**
- Git revert + CI rerun

**Staging:**
- Database backup restore (if schema changes)
- Git revert + redeployment
- Test data regeneration if needed

**Production:**
- Database backup restore (if destructive data change)
- Git revert + redeployment
- Customer notification if applicable
- Postmortem after rollback

## 15. Environment Consistency

Environment consistency reduces release risk and enables predictable rollbacks.

**Principle:** If it works in Staging, it should work in Production.

**Enablers:**
- Same configuration structure (differ only in values/secrets)
- Same monitoring and logging setup
- Same database schema and backup procedures
- Same external service integrations (sandbox ↔ live)
- Same resource constraints approximated (CPU, memory, network)

## 16. Final Principle

Environment consistency reduces release risk. Enforce environment boundaries, isolate configuration and secrets, prevent data leakage, and ensure staging mirrors production.
