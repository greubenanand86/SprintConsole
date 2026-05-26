# Agent Prompts

Standalone prompt definitions for every AI agent in the shared organization.

These files define mission, authority, inputs, outputs, decision criteria, and escalation triggers. They are the source of truth for agent behaviour. Hook scripts in `claude/hooks/` implement the runtime execution.

## Agent index

### Portfolio tier
| File | Agent | Scope |
|---|---|---|
| `portfolio-tpm-agent.md` | Portfolio TPM | Cross-product routing, shared platform decisions, priority conflicts |

### Product tier (shared across all products)
| File | Agent | Scope |
|---|---|---|
| `tpm-agent.md` | TPM | Sprint execution, release oversight, risk translation |
| `pm-agent.md` | Product Manager | Story creation, acceptance criteria, product acceptance |
| `ux-agent.md` | UX / Design | User flows, design system, accessibility |
| `architect-agent.md` | Architecture | Stack decisions, API design, technical governance |
| `delivery-coordinator-agent.md` | Delivery Coordinator | Sprint flow, blockers, capacity, dependencies |
| `web-frontend-agent.md` | Web Frontend | React implementation, design system, accessibility |
| `mobile-agent.md` | React Native Mobile | Cross-platform mobile, Expo, shared components |
| `backend-api-agent.md` | Backend & API | APIs, auth, data model, structured logging |
| `qa-agent.md` | QA Lead | Test plans, functional validation, regression, accessibility |
| `deploy-agent.md` | Deploy Specialist | Deployment readiness, environment checks, rollback plan |
| `release-risk-agent.md` | Release Readiness & Risk | Risk score, QA/PA gates, rollback, monitoring readiness |
| `security-agent.md` | Security | Auth/authz, secrets, dependencies, API security, PII |
| `legal-compliance-agent.md` | Legal & Compliance | Privacy, consent, accessibility, student data, third-party SDK |
| `monitoring-agent.md` | Monitoring | Post-release health, crash/error/performance signals |
| `incident-agent.md` | Incident Response | Severity classification, rollback recommendation, postmortem |
| `analytics-agent.md` | Analytics | Event definitions, naming conventions, privacy, dashboard impact |
| `finops-agent.md` | FinOps | Cloud cost, AI token usage, optimization options |
| `product-memory-agent.md` | Product Memory | Durable decisions, rationale, learnings, constraints |

## Format

Each prompt file follows the structure defined in `TIER_1_AGENT_PROMPTS.md`:
- Mission
- Authority & Constraints (may / may not)
- Inputs
- Outputs
- Execution (step-by-step)
- Decision Criteria
- Escalation Triggers

## Relationship to hook scripts

Prompt files define behaviour. Hook scripts execute it. The two are kept separate so prompts can be updated without touching runtime code, and vice versa.
