# Agent Formalization Roadmap v1.0
## From Governance to Executable Agents

**Date:** 2026-05-25  
**Status:** Ready to begin Tier 1 implementation and Tier 2 observation  
**Scope:** All 17 agents across 3 phases

---

## Executive Summary

SprintOps Console has adopted 12 governance standards (ADR-001 through ADR-012) and operationalized 6 critical governance gaps. Now we're formalizing AI agents to execute these standards.

**Phase 1 (Current):** Formalize Tier 1 agents (4 agents) — **READY TO DEPLOY**
**Phase 2 (Weeks 5–10):** Observe Tier 2 agents during sprints (6 agents) — **OBSERVATION FRAMEWORK READY**
**Phase 3 (Weeks 10+):** Formalize Tier 2 agents + deploy remaining Tier 3 agents (7 agents) — **DECISION FRAMEWORK READY**

---

## Phase 1: Tier 1 Agent Formalization (NOW)

### Tier 1 Agents (Executive & Product Decision-Makers)

| Agent | Role | Status | Prompt | Deployment |
|-------|------|--------|--------|-----------|
| **TPM Agent** | Escalation, risk translation, sprint coordination | ✅ READY | TIER_1_AGENT_PROMPTS.md §1 | Week 1–2 |
| **Product Manager Agent** | Feature definition, acceptance, prioritization | ✅ READY | TIER_1_AGENT_PROMPTS.md §2 | Week 1–2 |
| **UX Agent** | Workflows, accessibility, design consistency | ✅ READY | TIER_1_AGENT_PROMPTS.md §3 | Week 1–2 |
| **Architecture Agent** | API design, security design, scalability | ✅ READY | TIER_1_AGENT_PROMPTS.md §4 | Week 1–2 |

### Deployment Process

Each Tier 1 agent is deployed as:
1. Standalone jira.sh hook (runs on story state transition)
2. Claude API call with agent context + specific prompt
3. Comment output to Jira with verdict and rationale

**Deployment steps:**
1. Create agent script (e.g., tpm-agent.sh, pm-agent.sh, ux-agent.sh, architect-agent.sh)
2. Source jira.sh (for shared AGENT_CONTEXT, functions)
3. Define trigger conditions (e.g., TPM Agent runs when escalation tag detected)
4. Implement decision flow per prompt
5. Output comment with standard format (verdict, rationale, next steps)
6. Test with 2–3 stories before declaring "live"

### Authority & Guardrails

**TPM Agent:**
- ✅ May escalate, arbitrate conflicts, approve/block releases
- ❌ May NOT override governance, make product decisions, deploy to production

**Product Manager Agent:**
- ✅ May create/reject/refine stories, approve acceptance
- ❌ May NOT bypass UX/Architecture, override QA, make technical decisions

**UX Agent:**
- ✅ May reject UX, request redesign, block inaccessible features
- ❌ May NOT make product decisions, override accessibility standards, implement code

**Architecture Agent:**
- ✅ May reject architecture, request redesign, escalate security concerns
- ❌ May NOT override Security Agent, make product decisions, implement code

### Integration Points

**TPM Agent inputs:**
- Escalation comments from any agent
- Sprint metrics (velocity, predictability, incident count)
- Release Risk verdicts
- Blocker identification

**Product Manager Agent inputs:**
- User feedback, customer requests
- Feature discovery, market signals
- QA findings, UX friction reports
- Engineering feasibility feedback

**UX Agent inputs:**
- Story with business objective (from PM)
- Integration requirements
- Accessibility scope
- User research, competitive analysis

**Architecture Agent inputs:**
- Story with AC + UX design
- Performance constraints
- Scalability requirements
- Security considerations

---

## Phase 2: Tier 2 Agent Observation (Weeks 5–10)

### Tier 2 Agents (Execution & Release Critical Path)

| Agent | Role | Status | Observation Rules | Formalization |
|-------|------|--------|-------------------|--|
| **Security Agent** | Code security review, design safety | OBSERVE | TIER_2_OBSERVATION_RULES.md §I | Week 10+ |
| **QA Agent** | Testing, regression, usability | OBSERVE | TIER_2_OBSERVATION_RULES.md §II | Week 10+ |
| **Deploy Agent** | Staging deployment, checklist gating | OBSERVE | TIER_2_OBSERVATION_RULES.md §III | Week 10+ |
| **Release Risk Agent** | Risk assessment, rollout strategy | OBSERVE | TIER_2_OBSERVATION_RULES.md §IV | Week 10+ |
| **Monitoring Agent** | Post-release monitoring, health check | OBSERVE | TIER_2_OBSERVATION_RULES.md §V | Week 10+ |
| **Incident Agent** | Incident classification, postmortem | OBSERVE | TIER_2_OBSERVATION_RULES.md §VI | Week 10+ |

### Observation Framework

For 2–3 sprints (Weeks 5–10), we **do NOT formalize** Tier 2 agent prompts. Instead:

1. **Manually execute Tier 2 workflows** (human agent for now)
2. **Collect data** per observation rules (checklists, metrics, decision patterns)
3. **Identify natural patterns** (when do agents step in? when do they conflict?)
4. **Refine thresholds** (what criteria distinguish Green/Yellow/Red?)
5. **Capture edge cases** (what breaks? what decisions stall?)

### Data Collection (Per Agent)

**Security Agent:**
- When does security review happen? (design-time? code-time? both?)
- What % of PRs get blocked? Rate by reason?
- Are there false positives (overridden without issue)?
- Are there false negatives (bugs escaped)?

**QA Agent:**
- How long does QA take? By feature type?
- What % of stories get blocked? Rate by reason?
- QA escape rate post-release?
- Does QA detect UX friction?

**Deploy Agent:**
- How many deployments per week? Success rate?
- What checklist items most often fail?
- How long from approval to production?
- Does Deploy Agent catch staging issues?

**Release Risk Agent:**
- What % Green / Yellow / Red?
- Does verdict align with outcome? Accuracy rate?
- What risk factors drive Yellow/Red?
- Are there story types with consistent verdicts?

**Monitoring Agent:**
- What % of releases have issues post-release?
- How quickly are issues detected?
- Is 24–48h window sufficient? Do issues appear after?
- What metrics most useful for detection?

**Incident Agent:**
- Are severity classifications consistent?
- How quickly is root cause identified?
- How often is rollback viable?
- Do postmortem prevention steps get implemented?

### Output: Evidence-Based Formalization

At end of Phase 2 (Week 10), we have:
- **Quantitative data** (timing, success rates, accuracy)
- **Natural patterns** (when agents are needed, how they coordinate)
- **Decision thresholds** (what makes an assessment Green vs. Yellow vs. Red)
- **Conflict resolution** (where agents disagree, how to arbitrate)
- **Edge cases** (what breaks, what decisions stall)

This evidence drives formalization of Tier 2 prompts without speculation.

---

## Phase 3: Tier 2 Formalization & Tier 3 Deployment (Week 10+)

### Tier 3 Agents (Specialized Support)

| Agent | Role | Needs |
|-------|------|-------|
| **Web Frontend Agent** | React implementation | Explicit workflow (when to start? when to stop?) |
| **React Native Mobile Agent** | React Native + Expo implementation | Integrated mobile workflow, TestFlight gates |
| **Backend / API Agent** | API implementation, business logic | Explicit API contract validation |
| **Analytics Agent** | Feature adoption, usage metrics | Pre-release analytics validation gate |
| **Legal & Compliance Agent** | Risk identification (not legal sign-off) | Explicit scope + escalation rules |
| **Delivery Coordinator** | Dependency tracking, blocker escalation | Explicit dependency pre-flight check |
| **FinOps Agent** | Cost tracking, optimization | Cost estimation thresholds, cost budget |

### Phase 3 Deliverables (Week 10+)

1. **Tier 2 formalized prompts** (based on Phase 2 evidence)
   - Security Agent prompt (with timing, authority rules)
   - QA Agent prompt (with coverage thresholds)
   - Deploy Agent prompt (with checklist discipline, approval flow)
   - Release Risk Agent prompt (with quantitative criteria for Green/Yellow/Red)
   - Monitoring Agent prompt (with detection rules, monitoring window logic)
   - Incident Agent prompt (with severity quantitative thresholds)

2. **Tier 3 agent definitions** (high-level prompts)
   - Web Frontend Agent workflow
   - React Native Mobile Agent workflow (integrated with main release)
   - Backend / API Agent workflow
   - Analytics Agent workflow
   - etc.

3. **Agent coordination framework** (how agents work together)
   - Escalation paths (when does each agent escalate?)
   - Conflict resolution (who wins if agents disagree?)
   - Integration points (when does each agent step in?)

---

## Governance Clarifications: What's Resolved NOW

### 6 Critical Governance Gaps (Resolved in GOVERNANCE_CLARIFICATIONS.md)

✅ **1. Production Deployment Approval Chain**
- Explicit flow: Story → Release Risk assessment → TPM approval → Deploy Agent (with checklist) → Production
- Pre-release checklist: 10 mandatory items (QA, Product Acceptance, Rollback, Release notes, Monitoring, Security, Compliance, Analytics, Environment parity)
- Gate conditions: Story must pass all checklist items before Deploy Agent deploys to production

✅ **2. Deploy Agent Authority Boundaries**
- ✅ Authorized: Deploy to staging, validate checklist, gate production deployment, execute staged rollout, validate environment parity
- ❌ Not authorized: Deploy to production without approval chain, skip checklist, override Release Risk Red verdict

✅ **3. TPM Agent Authority Boundaries**
- ✅ Authorized: Escalate, arbitrate conflicts (per Decision Hierarchy), approve/block releases, recommend delay, request reviews
- ❌ Not authorized: Override governance, make product/technical decisions, deploy to production

✅ **4. Security Review Timing (Three-Stage)**
- Stage 1 (Design-time): Architect + Security review design together
- Stage 2 (Code-time): Security reviews code during code review
- Stage 3 (Pre-release): Security confirms no new vulns before production

✅ **5. Product Memory Storage Rules**
- Real-time: Architecture, UX, Security decisions (as soon as approved)
- Post-release: Release learnings, rollbacks, monitoring gaps, postmortems
- Quarterly: Superseded decisions marked stale, emerging patterns identified

✅ **6. Mobile Release Integration**
- Mobile features follow same workflow as web (Design → Dev → Code Review → QA → Acceptance → Risk → Deploy)
- Mobile-specific gates: TestFlight stable, internal testing passed, crash-free <1%, metadata approved
- Coordination decision: Release Risk Agent decides parallel vs. sequential deployment

---

## Blocking Ambiguities: What Still Needs Human Decision

### 13 Ambiguities Requiring Stakeholder Input (BLOCKING_AMBIGUITIES.md)

**Blocking (Decide before first production release):**
1. ⚠️ Human approver role & process (who approves? how?)
2. ⚠️ High-risk release definition (what makes release high-risk?)
3. ⚠️ Incident severity quantitative thresholds (SEV-1 = X% impact?)

**High Priority (Decide before Tier 2 formalization):**
4. ⚠️ Staged rollout defaults (%, timing)
5. ⚠️ Feature flags vs. staged rollout (when each?)
6. ⚠️ Monitoring window duration (24h? 48h? configurable?)
7. ⚠️ Security escalation threshold (all blocks escalate?)

**Medium Priority (Decide during Phase 2 observation):**
8. ⚠️ Stable state criteria (metrics for "stable"?)
9. ⚠️ Compliance review scope (all stories? data-sensitive only?)
10. ⚠️ Mobile-web release timing (parallel? sequential?)
11. ⚠️ Mobile beta validation (duration, device coverage?)
12. ⚠️ Rollback dry-run requirement (all releases? high-risk only?)

**Low Priority (Can defer or skip):**
13. ⚠️ FinOps escalation threshold (cost limit?)

**Recommended decision process:**
1. Block 1–3 must be decided **before Week 1 (Phase 1 start)**
2. High 4–7 should be decided **before Week 5 (Phase 2 start)**
3. Medium 8–12 can be decided **during Phase 2 (Weeks 5–10)**
4. Low 13 can be deferred indefinitely (if cost unconstrained)

---

## Timeline & Next Steps

### Week 1–2: Deploy Tier 1 Agents
- Create tpm-agent.sh, pm-agent.sh, ux-agent.sh, architect-agent.sh
- Deploy to Jira hooks (test with 2–3 stories)
- Verify agent comments, verdicts, coordination
- Resolve any blockers in Tier 1 execution

**Decision required:** 3 blocking ambiguities (human approver, high-risk definition, incident severity)

### Week 3–4: First Production Release (with Tier 1 agents)
- Use Tier 1 agents to shepherd story through workflow
- Collect Tier 1 agent feedback (timing, accuracy, coordination)
- Refine Tier 1 prompts based on real usage
- Monitor for blocking ambiguities (where does process break?)

### Week 5–10: Phase 2 Observation (Tier 2 agents)
- **Do NOT automate Tier 2 agents.** Manually execute workflows.
- Collect data per TIER_2_OBSERVATION_RULES.md
- 2–3 production releases with manual Tier 2 execution
- Identify natural patterns, bottlenecks, conflicts

**Ongoing decisions:** High-priority ambiguities (staged rollout, monitoring window, etc.)

### Week 10+: Phase 3 Formalization (Tier 2 agents)
- Formalize Tier 2 agent prompts based on Phase 2 evidence
- Deploy Tier 2 agents (security, QA, deploy, release risk, monitoring, incident)
- Define Tier 3 agent workflows (frontend, mobile, backend, analytics, etc.)
- Build complete agent ecosystem

---

## Success Criteria

### Phase 1 Success (Weeks 1–4)
- ✅ Tier 1 agents (TPM, PM, UX, Architect) deployed and active
- ✅ 3 production releases completed with Tier 1 agent governance
- ✅ No governance violations in releases
- ✅ Tier 1 agents' verdicts align with outcomes (high accuracy)
- ✅ Blocking ambiguities resolved (human approver, high-risk definition, severity thresholds)

### Phase 2 Success (Weeks 5–10)
- ✅ Tier 2 observation data collected (per TIER_2_OBSERVATION_RULES.md)
- ✅ 2–3 production releases with observed Tier 2 workflows
- ✅ Natural patterns identified (when each agent needed, how they coordinate)
- ✅ Decision thresholds quantified (Green/Yellow/Red criteria)
- ✅ High-priority ambiguities resolved (staged rollout, monitoring window, etc.)

### Phase 3 Success (Week 10+)
- ✅ Tier 2 agent prompts formalized and deployed
- ✅ Tier 3 agent workflows defined
- ✅ Full 17-agent ecosystem operational
- ✅ Governance standards fully executed by agents
- ✅ Release cycle time <7 days (code complete → production)
- ✅ Incident response time <1 hour (detection → resolution)

---

## Documents by Purpose

| Document | Purpose | Audience | When |
|----------|---------|----------|------|
| **AGENT_EMERGENCE_ANALYSIS.md** | Observed patterns from governance | Architects, TPM | Weeks 1–2 (reference) |
| **GOVERNANCE_CLARIFICATIONS.md** | Operational rules for 6 gaps | All agents, humans | Week 1 (deploy) |
| **TIER_1_AGENT_PROMPTS.md** | Formalized prompts for 4 agents | Developers (agent builders) | Week 1 (implement) |
| **TIER_2_OBSERVATION_RULES.md** | Data collection framework | Data collectors (during Phase 2) | Week 5 (activate) |
| **BLOCKING_AMBIGUITIES.md** | Human decision checklist | Decision-makers (executives, PM, TPM) | Weeks 1, 5, 10 (decide) |
| **AGENT_FORMALIZATION_ROADMAP.md** | This document (timeline, success criteria) | All stakeholders | Week 1 (alignment) |

---

## Risk Mitigation

### Risk 1: Tier 1 Agents Conflict
**Mitigation:** 
- TPM Agent arbitrates per Decision Hierarchy (Security > Stability > Maintainability > Scalability > Dev > Performance > Sophistication)
- Escalate unresolvable conflicts to human (explicit `[ESCALATE → HUMAN]` comment)

### Risk 2: Production Deployment Blocked
**Mitigation:**
- Pre-release checklist is objective (pass/fail, not subjective)
- Deploy Agent can't skip items (structural constraint)
- If item fails, story returns to "Ready for Release" with blocker reason
- Blocker resolution is tracked (time to unblock)

### Risk 3: Tier 2 Observation Disrupts Releases
**Mitigation:**
- Tier 2 agents are NOT formalized; we manually execute for 2–3 releases
- Human judgment + governance rules drive Tier 2 decisions, not automated agents
- No risk of agent mistakes during observation phase
- After Phase 2, formalized Tier 2 prompts are evidence-based

### Risk 4: Blocking Ambiguities Delay Deployment
**Mitigation:**
- 3 blocking ambiguities must be decided Week 1 (before Tier 1 deployment)
- Other ambiguities can be decided during observation phase
- Each ambiguity has recommended decision process (no ambiguity left unresolved)

### Risk 5: Tier 1 Agents Are Too Strict
**Mitigation:**
- Tier 1 prompts include "approved with conditions" option
- TPM Agent can override verdicts (with risk acknowledgment)
- Escalate to human if override needed (transparent decision)

---

## Conclusion

**We are ready to:**
1. Deploy Tier 1 agents (4 agents, 4 executable prompts)
2. Operationalize governance clarifications (6 gaps resolved)
3. Observe Tier 2 agent patterns (framework ready)
4. Identify and resolve blocking ambiguities (checklist of 13)

**Next action:** Decide 3 blocking ambiguities + deploy Tier 1 agents in Week 1.
