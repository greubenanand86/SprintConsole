# Metrics & Operational Dashboard Framework
## Version 1.0

## 1. Purpose

Defines organizational health metrics, release metrics, engineering metrics, product metrics, and operational intelligence to enable data-driven decisions. Provides visibility into delivery predictability, quality, efficiency, and AI governance effectiveness.

## 2. Core Principles

**Metrics exist to improve decisions, not to create artificial pressure.**

- Track what matters (delivery, quality, efficiency, user impact)
- Avoid vanity metrics (lines of code, commit count, etc.)
- Use metrics to identify problems, not to reward/penalize individuals
- Update metrics monthly or quarterly (not daily)
- Always include context and drivers (why did this change?)

## 3. TPM (Technical Program Manager) Dashboard

**Purpose:** Track sprint health, delivery predictability, release stability, and roadmap progress.

**Metrics:**

| Metric | Definition | Target | Cadence |
|--------|-----------|--------|---------|
| Sprint Predictability | % of committed work completed on time | 80%+ | Weekly |
| Blocked Work | % of stories blocked by dependencies/tech issues | <5% | Weekly |
| Release Stability | Median time from "code complete" to production | <2 weeks | Per release |
| Incident Frequency | Critical incidents per month (P0/P1) | <1 per month | Monthly |
| Delivery Velocity | Story points completed per sprint | Trend, not absolute | Weekly |
| Carryover Rate | % of stories rolling into next sprint | <10% | Weekly |
| Release Success Rate | % of releases with no rollbacks | 95%+ | Per release |
| QA Escape Rate | Bugs found in production / total bugs | <2% | Monthly |
| Time-to-Value | Days from feature complete to user adoption | Trend | Per release |

**Dashboard View:**
```
[Sprint Name] Week 5 — Velocity 34 pts | Predictability 85% | Blocked 2%
Incidents this sprint: 0 | Carryover next: 3 stories | Release planned: 2026-06-15
```

## 4. Engineering Dashboard

**Purpose:** Track code quality, deployment efficiency, and lead time for delivery.

**Metrics:**

| Metric | Definition | Target | Cadence |
|--------|-----------|--------|---------|
| Build Success Rate | % of CI builds that pass without error | 95%+ | Continuous |
| Deployment Frequency | Deployments per week (to staging + prod) | 1-2/week | Weekly |
| Lead Time | Days from first commit to production | <7 days | Per release |
| Cycle Time | Days from first commit to merge | <3 days | Weekly |
| Technical Debt Growth | Story points of tech debt added per sprint | <5% of velocity | Weekly |
| Test Coverage | % of code covered by unit/integration tests | 70%+ | Weekly |
| PR Review Time | Median time from PR open to merge | <24 hours | Weekly |
| Code Review Cycle | Number of review rounds per PR | <2 rounds | Weekly |
| Dependency Vulnerability Scan | High/Critical vulnerabilities blocking CI | 0 | Continuous |
| Type Safety | % of codebase using TypeScript (not JSX) | Trend to 100% | Monthly |

**Dashboard View:**
```
Build success: 97% | Deployments this week: 2 | Lead time: 4.5 days
Test coverage: 68% | Tech debt velocity: 4 pts | PR review time: 18 hours
```

## 5. Product Dashboard

**Purpose:** Track feature adoption, user engagement, retention, and user experience quality.

**Metrics:**

| Metric | Definition | Target | Cadence |
|--------|-----------|--------|---------|
| Feature Adoption | % of active users using new feature | >50% by week 4 | Weekly |
| Funnel Completion | % of users completing key workflows | 70%+ | Weekly |
| User Retention | % of users returning after week 1 | >60% | Monthly |
| UX Friction | Support tickets / feature usage ratio | <0.1 | Monthly |
| Crash-Free Sessions | % of sessions without crashes | 99%+ | Daily |
| Error Rate | API errors per 1000 requests | <5 | Daily |
| Performance | P95 response time for key APIs | <500ms | Daily |
| Analytics Completeness | % of expected events firing | >95% | Weekly |
| NPS (Net Promoter Score) | If applicable, customer satisfaction | >40 | Quarterly |
| Feature Utilization | % of implemented features used monthly | >70% | Monthly |

**Dashboard View:**
```
Feature adoption (new release): 45% | Funnel completion: 72% | Retention: 62%
Crash-free sessions: 99.7% | Error rate: 2.3/1000 | UX friction: 0.08
```

## 6. Operational Dashboard

**Purpose:** Track production reliability, QA effectiveness, and release quality.

**Metrics:**

| Metric | Definition | Target | Cadence |
|--------|-----------|--------|---------|
| Incident Frequency | Critical incidents per month (P0/P1) | <1 per month | Monthly |
| Incident Duration | Median time to resolve critical incident | <2 hours | Monthly |
| Rollback Frequency | Rollbacks per release | <5% | Per release |
| Release Failure Rate | % of releases requiring rollback | <3% | Per release |
| QA Escape Rate | Bugs found in production / total bugs | <2% | Monthly |
| App Store Rejection Rate | Rejected mobile app submissions | 0 | Per submission |
| SLA Uptime | Production availability | 99.9%+ | Daily |
| Security Incident Rate | Security incidents per quarter | 0 | Quarterly |
| Data Breach Incidents | Unintended data exposures | 0 | Quarterly |
| On-Call Escalations | Incidents requiring escalation | <20% | Monthly |

**Dashboard View:**
```
Incidents this month: 0 | Last rollback: 2026-05-01 | Uptime: 99.95%
QA escape rate: 1.2% | App rejections: 0 | On-call escalations: 12%
```

## 7. AI Governance Dashboard

**Purpose:** Track AI-assisted delivery, governance compliance, and agent effectiveness.

**Metrics:**

| Metric | Definition | Target | Cadence |
|--------|-----------|--------|---------|
| AI-Generated PR Count | % of PRs auto-generated by AI agents | <20% | Weekly |
| AI Deployment Assist Rate | % of deployments using AI validation | <50% | Weekly |
| Governance Violations | Stories with architecture/security/compliance issues | 0 | Weekly |
| Manual Override Frequency | % of AI decisions overridden by humans | <5% | Weekly |
| Agent Effectiveness | % of agent recommendations accepted | >70% | Monthly |
| Security Agent Sign-Off Rate | % of production releases with security review | 100% | Per release |
| Test Coverage by AI | % of tests written/reviewed by AI | Track only | Monthly |
| Escalation Rate | % of stories escalated to TPM | <10% | Weekly |
| Decision Traceability | % of decisions recorded in Product Memory | >80% | Monthly |
| Agent Comment Quality | % of agent comments that add value vs. noise | >80% | Monthly |

**Dashboard View:**
```
AI-generated PRs: 15% | Deployment assist: 40% | Governance violations: 0
Manual overrides: 3.2% | Agent effectiveness: 74% | Escalations: 8%
```

## 8. Metric Definitions & Calculation

### Sprint Predictability
**Formula:** `(committed story points - rolled over story points) / committed story points * 100`
**Interpretation:** Higher is better. Aim for 80%+ to enable reliable planning.
**Actions if low:** Identify blockers (dependencies, scope creep, estimation bias); adjust team capacity or scope.

### Deployment Frequency
**Formula:** `# of deployments to production / weeks`
**Target:** 1-2 per week (sustainable pace, not forced)
**Interpretation:** More frequent deployments indicate faster feedback, smaller batches, better rollback capability.
**Actions if low:** Identify CI/CD bottlenecks; consider feature flags; reduce batch size.

### Lead Time
**Formula:** `date(first commit) to date(deployed to production)`
**Target:** <7 days (faster feedback, smaller batch = less risk)
**Interpretation:** Shorter lead time enables quicker responses to issues.
**Actions if high:** Identify blockers (code review cycle, QA, release gates); parallelize where possible.

### Test Coverage
**Formula:** `(lines of code covered by tests) / total lines of code * 100`
**Target:** 70%+ (not 100% — some code doesn't need tests)
**Interpretation:** Higher coverage enables safer refactoring.
**Actions if low:** Add tests for critical paths; prioritize over coverage % number.

### Incident Frequency
**Formula:** `# of P0/P1 incidents / 30 days`
**Target:** <1 per month
**Interpretation:** Lower is better; indicates reliability and stability.
**Actions if high:** Conduct postmortems; implement prevention actions; focus on stability over speed.

### QA Escape Rate
**Formula:** `bugs found in production / (bugs found in QA + bugs found in production) * 100`
**Target:** <2%
**Interpretation:** Lower is better; indicates effective QA process.
**Actions if high:** Review QA test plans; expand test coverage; improve environment parity (staging = production).

### Feature Adoption
**Formula:** `# of users who used feature / # of active users * 100` (by week after launch)
**Target:** >50% by week 4
**Interpretation:** Fast adoption indicates good feature-market fit and UX.
**Actions if low:** Gather user feedback; improve discoverability; consider UX refinement or feature adjustment.

### Crash-Free Sessions
**Formula:** `(sessions without crashes) / total sessions * 100`
**Target:** 99%+ (industry standard)
**Interpretation:** Directly impacts user experience; even 1% crash rate affects millions of sessions at scale.
**Actions if low:** Prioritize bug fixes; increase monitoring; add error boundaries; improve testing.

## 9. Dashboard Review Cadence

**Weekly (TPM + Engineering Lead):**
- Sprint velocity, predictability, carryover
- Build success, deployment frequency
- Critical incidents, blockers
- AI governance violations

**Monthly (Product + TPM + Engineering):**
- Feature adoption, funnel completion, retention
- Technical debt growth, test coverage
- QA escape rate, incident frequency
- Agent effectiveness, decision traceability

**Quarterly (Executive + TPM + Product):**
- Release success rate, delivery velocity trends
- Customer satisfaction (NPS if applicable)
- Strategic roadmap progress
- Technical debt repayment progress

## 10. Dashboarding Tools

**Recommended:**
- Jira dashboard (built-in, requires minimal setup)
- Grafana + Prometheus (for infrastructure/performance metrics)
- GitHub Actions logs (for build/deployment metrics)
- Sentry / crash reporting (for error/crash metrics)
- Analytics platform (for product metrics — Amplitude, Segment, etc.)
- Custom spreadsheet (if tools don't cover everything)

**Rules:**
- Automate metric collection where possible (avoid manual spreadsheets)
- Make dashboards visible to team (broadcast on Slack, post in office)
- Review dashboards in sprint retrospectives
- Don't hide bad metrics (they indicate problems to fix, not failure)

## 11. Anti-Patterns

**Avoid:**

❌ **Vanity metrics:** Lines of code, number of commits, story points completed (can increase without benefit)

❌ **Individual metrics:** Commit count per developer, hours logged (invites gaming, burnout)

❌ **Targets without context:** "Increase deployment frequency to 5/week" without reason; may encourage smaller, riskier batches

❌ **Metrics as punishment:** "You missed 80% predictability; your bonus is reduced" (leads to padding estimates, risk aversion)

❌ **Static targets:** "Test coverage must always be >80%" (sometimes 60% is right; sometimes 90% is needed)

**Instead:**

✅ **Actionable metrics:** Deployment frequency, lead time, cycle time (indicate process health)

✅ **Team metrics:** Velocity, predictability, incident count (indicate team capability, not individual performance)

✅ **Context-aware targets:** "Lead time should trend downward; we're at 5 days, want <3" (recognizes improvement, not punishment)

✅ **Metrics as learning:** "QA escape rate is 3%; let's understand why and improve QA test coverage" (improvement mindset)

✅ **Flexible targets:** "Test coverage >70% for critical paths; 40%+ for utilities" (sensible, not arbitrary)

## 12. Data Integrity Rules

- **Single source of truth:** Each metric comes from one authoritative source (Jira for velocity, GitHub for build success, Sentry for crashes)
- **Automated collection:** Metrics collected via API/log analysis, not manual entry
- **Accessible definitions:** Team has written documentation of how each metric is calculated
- **No retroactive changes:** Definitions don't change mid-quarter (makes trends meaningless)
- **Transparency:** Metrics are visible to the team, not hidden in executive reports
- **Regular audit:** Monthly, verify that metric calculation still matches definition

## 13. Final Principle

**Metrics exist to improve decisions, not to create artificial pressure.**

Use metrics to:
- Understand delivery capability (velocity, predictability)
- Identify problems early (incident frequency, QA escape rate, lead time)
- Measure impact (feature adoption, retention, crash-free sessions)
- Improve processes (review dashboards in retrospectives, find bottlenecks)

Don't use metrics to:
- Punish individuals or teams
- Create unrealistic targets
- Hide problems (always report actual metrics, not goals)
- Justify decisions already made (metrics should inform, not retroactively validate)

A good metric helps you ask "why?" and leads to action. A bad metric just accumulates numbers.
