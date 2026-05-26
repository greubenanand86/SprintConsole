# Shared Governance

Standards, playbooks, and constraints that apply to every product in this repo.

A decision belongs here when it affects all products, is externally imposed, or has been proven stable across at least two products. Product-specific decisions belong in `products/{name}/architecture-notes.md` or `products/{name}/product-memory/`.

## What lives here

| Document | Purpose |
|---|---|
| `architecture.md` | Monorepo structure, target stack, decision hierarchy |
| `api-contract-standards.md` | Versioning, error format, auth, pagination |
| `security-baseline.md` | Auth, secrets, dependency governance, data protection |
| `environment-governance.md` | Environment tiers, deployment flow, secrets management |
| `release-management-playbook.md` | Release types, approval gates, rollback, monitoring window |
| `incident-management-playbook.md` | Severity classification, escalation flow, postmortem |
| `shared-package-strategy.md` | What belongs in `/packages`, coupling rules |
| `legal-compliance-governance.md` | Privacy, accessibility, consent, escalation triggers |
| `metrics-dashboard-framework.md` | Metric definitions, dashboard ownership, anti-patterns |
| `agent-role-specifications.md` | All 18 agent roles, authority, constraints |
| `repository-governance.md` | Branching, PR requirements, merge policy |

## What does not live here

- Product roadmaps → `products/{name}/roadmap.md`
- Product-specific architecture decisions → `products/{name}/architecture-notes.md`
- Release history for a product → `products/{name}/release-history.md`
- Team context, Jira project mapping → `products/{name}/jira-mapping.md`
- Product learnings and incident postmortems → `products/{name}/product-memory/`

## Governance rule

Documents in this directory are owned by the shared agent organization and the Portfolio TPM. Changes that affect only one product must not be made here — make them in the product workspace instead.
