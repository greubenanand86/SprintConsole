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
| **TPM Agent** | Escalation, risk translation, **recommendation** (not approval) | ✅ READY | TIER_1_AGENT_PROMPTS.md §1 | Week 1–2 |
| **Product Manager Agent** | Feature definition, **acceptance ownership** (QA validates correctness, PM validates value) | ✅ READY | TIER_1_AGENT_PROMPTS.md §2 | Week 1–2 |
| **UX Agent** | Workflows, accessibility, design consistency | ✅ READY | TIER_1_AGENT_PROMPTS.md §3 | Week 1–2 |
| **Architecture Agent** | API design, security design, scalability | ✅ READY | TIER_1_AGENT_PROMPTS.md §4 | Week 1–2 |

### Deployment Model: Advisory-First (Initially)

**Important distinction:** Agents *recommend* transitions and actions; humans review and approve before workflow moves.

Each Tier 1 agent is deployed as:
1. Standalone jira.sh hook (runs on story state transition)
2. Claude API call with agent context + specific prompt
3. Comment output to Jira with **recommendation** (not autonomous action)
4. Human reviews recommendation and transitions story manually (initially)

**Example flow (Advisory-First):**
```
UX Agent writes comment: "[UX DESIGNER] ✅ UX specified. Wireframes and accessibility approved. Ready for Architect review."
→ Human reads comment, verifies, manually transitions story to "Ready for Refinement"

Architect Agent writes comment: "[ARCHITECT] ✅ Architecture approved. Ready for development."
→ Human reads comment, verifies, manually transitions story to "Ready for Development"

TPM Agent writes comment: "[TPM RECOMMENDS PROCEED] Release Risk Green; checklist complete. Awaiting human approval."
→ Human reads comment, verifies checklist, reviews Release Risk verdict, makes production approval decision
```

**Future evolution (Automation, Phase 2+):** Once patterns stabilize, certain recommendations may be auto-executed (e.g., UX approval → auto-transition to "Ready for Refinement"), but always with audit trail and human override capability.

**Why advisory-first initially:**
- Agents are new; recommendations need human validation before automation
- Builds confidence in agent accuracy before autonomous transitions
- Easy to adjust agent logic without unraveling autonomous workflows
- Human retains explicit control over all state transitions during Phase 1–2

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

**Goal:** Operational clarity, not maximum agent count. We'll observe which roles naturally emerge, then formalize only the necessary agents. Consolidation is expected.

| Agent Role | Status | Observation Rules | Formalization Decision |
|-----------|--------|-------------------|----------------------|
| **Security Review** (Code + Design-time) | OBSERVE | TIER_2_OBSERVATION_RULES.md §I | Consolidate or split? Observe first. |
| **QA & Testing** (Correctness validation) | OBSERVE | TIER_2_OBSERVATION_RULES.md §II | Consolidate with other QA functions? |
| **Release Gating** (Checklist validation) | OBSERVE | TIER_2_OBSERVATION_RULES.md §III | Part of Deployment, or separate agent? |
| **Risk Assessment** (Release readiness) | OBSERVE | TIER_2_OBSERVATION_RULES.md §IV | Consolidate with Release Gating? |
| **Post-Release Monitoring** (Health check) | OBSERVE | TIER_2_OBSERVATION_RULES.md §V | Standalone or part of Release? |
| **Incident Response** (Classification, postmortem) | OBSERVE | TIER_2_OBSERVATION_RULES.md §VI | Consolidate with Monitoring? |

**Key principle:** Do NOT formalize agents until Phase 2 observation reveals natural role boundaries. Consolidate roles that naturally work together; split roles that create conflicts. The goal is clarity and efficiency, not a predetermined agent count.

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

## Phase 3: Tier 2 Formalization & Flexible Agent Definition (Week 10+)

### Phase 2 Observation Output: Consolidated Agent Roles

Based on Phase 2 observation, we expect consolidation. Example patterns:

- **Security + Code Review Agent** (design-time + code-time security validation; single agent)
- **QA + Testing Agent** (correctness validation, regression, accessibility)
- **Release Readiness Agent** (checklist gating + risk assessment + rollout coordination)
- **Monitoring + Incident Response Agent** (post-release health → incident classification → postmortem)

**NOT predetermined** — Phase 2 will reveal which consolidations work; we formalize based on evidence.

### Tier 3 Support Functions (As Needed)

Only formalize Tier 3 agents if Phase 2 observation reveals:
- Clear customer need (e.g., "we keep manually checking mobile TestFlight status; automate this")
- Natural role boundary (e.g., "Analytics always validates pre-release; make it an agent")
- Operational efficiency (e.g., "Manually estimating costs; automate with FinOps checks")

**Do NOT create:**
- **Web Frontend Agent** as separate agent (unless Phase 2 reveals it's needed)
- **React Native Mobile Agent** unless mobile-specific testing becomes major bottleneck
- **Backend / API Agent** unless API contract validation keeps causing delays
- **Delivery Coordinator** if TPM + agents handle dependencies well
- **FinOps Agent** if costs stay unconstrained

The goal is **operational clarity**, not agent proliferation.

### Phase 3 Deliverables (Week 10+)

1. **Tier 2 formalized prompts** (based on Phase 2 consolidation evidence)
   - Consolidated Security Agent (design + code review)
   - QA + Testing Agent
   - Release Readiness Agent (checklist + risk + rollout)
   - Monitoring + Incident Agent
   - +/- Specialized agents based on observation

2. **Consolidation rationale document**
   - Why we consolidated X agents
   - Why we kept Y agents separate
   - How consolidated agents coordinate
   - Decision criteria for future role splits

3. **Agent coordination framework** (how agents work together)
   - Escalation paths (when does each agent escalate?)
   - Conflict resolution (who wins if agents disagree?)
   - Integration points (when does each agent step in?)
   - Advisory-first communication model for all agents

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

### Week 1–2: Deploy Tier 1 Agents (Advisory-First Model)
- Create tpm-agent.sh, pm-agent.sh, ux-agent.sh, architect-agent.sh
- Deploy to Jira hooks as **advisory agents** (write recommendations in comments)
- Manual workflow transitions (human reads agent recommendation, manually transitions story)
- Test with 2–3 stories to verify agent logic and accuracy
- Build confidence in agent recommendations before automation

**Approval process:**
- TPM Agent recommends → Human makes production approval decision
- Architect Agent recommends → Human manually transitions to next state
- PM Agent approves acceptance → Human manually transitions to next state
- UX Agent approves design → Human manually transitions to next state

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

### Phase 1 Success (Weeks 1–4) — Advisory-First Model
- ✅ Tier 1 agents (TPM, PM, UX, Architect) deployed and **recommending** (not automating)
- ✅ 3 production releases completed with Tier 1 agent governance
- ✅ Human approves all state transitions (advisory-first flow working)
- ✅ No governance violations in releases
- ✅ Tier 1 agent recommendations align with human decisions (high accuracy)
- ✅ Blocking ambiguities resolved (human approver, high-risk definition, severity thresholds)

### Phase 2 Success (Weeks 5–10) — Observe & Consolidate
- ✅ Tier 2 observation data collected (per TIER_2_OBSERVATION_RULES.md)
- ✅ 2–3 production releases with observed Tier 2 workflows
- ✅ Natural role boundaries identified (which functions belong together?)
- ✅ Decision thresholds quantified (Green/Yellow/Red criteria)
- ✅ Consolidation patterns documented (e.g., "Security + Code Review should be one agent")
- ✅ High-priority ambiguities resolved (staged rollout, monitoring window, etc.)

### Phase 3 Success (Week 10+) — Formalize Consolidated Agents
- ✅ Tier 2 agent prompts formalized based on Phase 2 consolidation evidence
- ✅ Consolidated agent workflows operational (e.g., Security Agent handles design + code review)
- ✅ Governance standards fully executed by agents
- ✅ **Flexible agent count** (not 17 agents; only as many as operational clarity requires)
- ✅ Advisory-first workflow continues for new/complex decisions
- ✅ Automation introduced only after patterns stabilize
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
