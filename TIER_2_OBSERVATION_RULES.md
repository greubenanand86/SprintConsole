# Tier 2 Agent Observation Rules
## How to Monitor and Formalize Development Execution Agents

**Date:** 2026-05-25  
**Scope:** QA Agent, Deploy Agent, Release Risk Agent, Monitoring Agent, Incident Agent, Security Agent  
**Purpose:** Capture natural behavioral patterns before formalizing prompts in formalization phase 2  
**Observation Window:** 2–3 sprints of real story execution

---

## Overview

Tier 2 agents are critical to release execution but their workflows depend heavily on Tier 1 agent decisions. Rather than formalizing prompts now, we observe:

1. **Natural emergence:** When are Tier 2 agents most helpful? When do they block or conflict?
2. **Integration points:** How do Tier 2 agents coordinate with Tier 1 agents?
3. **Failure modes:** Where do things break? What decisions get pushed to human?
4. **Timing:** When should each agent step in? Too early = wasted work; too late = blocked release

After 2–3 sprints of observation, we'll formalize Tier 2 prompts with real evidence about what works.

---

## I. Security Agent — Observation Rules

### Current State (Governance Clarifications v1.0)
- **Design-time review:** Architect + Security review design together
- **Code-time review:** Security reviews code during code review gate
- **Pre-release review:** Security confirms no new vulns before production

### What to Observe

**Dimension 1: Timing**
- When does Security Agent actually step in? (Design review? Code review? Both?)
- How long does security review take? (minutes? hours? days?)
- Does late security review cause rework? (code rejected? design rejected?)
- Are there features that skip security review? (low-risk features? internal tools?)

**Dimension 2: Authority & Veto Power**
- Does Security Agent block code merges? (If so, how often? % of PRs?)
- Does Security Agent block release? (If so, how often? % of stories?)
- When Security Agent blocks, is it due to: policy gap, code issue, or design issue?
- Does anything override Security Agent verdict? (TPM? Human? Architect?)

**Dimension 3: Coordination**
- How does Security Agent work with Architect Agent? (parallel? sequential?)
- Do Security and Architect ever disagree? (If so, how is it resolved?)
- Does Security Agent need to review integration changes? (third-party API, webhook, email service?)
- Are there recurring security issues? (hardcoded secrets? missing validation? same type of fix?)

**Dimension 4: False Positives / Negatives**
- Are Security Agent concerns ever overridden without issue? (false positive = too strict)
- Do bugs escape that Security Agent should have caught? (false negative = too loose)
- Are there patterns in overrides? (certain story types? certain developers?)

### Observation Checklist

For each story with a Security Agent involvement, record:

```
Story: {KEY}
Security Agent first involvement: {state} (design review? code review? pre-release?)
Timing: {date-in} → {date-out} (how long did security review take?)
Verdict: [✅ APPROVED | ⚠️ APPROVED WITH CONDITIONS | ❌ BLOCKED]

If approved:
- Type of review: Design | Code | Pre-release | Multiple
- Issues found: {none | minor | major | critical}
- Category: {auth | data-access | secrets | dependencies | validation | error-handling | other}

If blocked:
- Reason: {specific security concern}
- Resolution time: {how long to fix and resubmit?}
- Root cause: {design issue | code issue | missing validation | other}
- Escalated to TPM? {yes | no}
- Escalated to human? {yes | no}

If approved with conditions:
- Condition: {specific monitoring, documentation, or future work required}
- Will condition be tracked? {yes in tech debt | yes in monitoring | no}

Interaction with Architect Agent:
- Did they review together? {yes | no}
- Did Architect and Security disagree? {yes → {outcome} | no}
- Did Architect approval come first? {yes | no}
```

### Decision Points for Formalization

After 2–3 sprints, answer:

1. **Timing:** Should Security Agent review happen at:
   - Design-time only? (catch issues early, but needs time before code)
   - Code-time only? (fast, but code rework if issue found)
   - Both? (thorough, but double effort)
   - Or dynamic? (simple features = code-time only; complex = both)

2. **Authority:** When Security Agent blocks, what happens next?
   - Dev fixes code immediately (low friction)
   - Requires architecture redesign (high friction; escalates to TPM?)
   - Requires product decision (design trade-off; escalates to PM?)
   - Requires human decision (risk acceptance; escalates to human?)

3. **Coordination:** Should Architect and Security Agent:
   - Review simultaneously? (faster, but need both available)
   - Architect first, then Security? (sequential; slower but clear order)
   - Security-first? (rare; only if design has obvious security gap)

4. **Escalation:** What types of blocks should escalate to TPM immediately?
   - Auth/data-access issues? (always escalate?)
   - Dependency vulnerabilities? (only if High/Critical?)
   - Secrets in code? (always escalate?)

---

## II. QA Agent — Observation Rules

### Current State (Governance Clarifications v1.0)
- QA Agent reviews code after code review
- QA Agent may block release
- QA may detect usability issues (UX friction) that should be escalated to UX Agent

### What to Observe

**Dimension 1: Test Coverage & Regression Risk**
- What % of code does QA actually test? (100%? 80%? only critical paths?)
- How many bugs does QA find per story? (0? 1–5? >5?)
- Are bugs found in QA ever repeated? (same bug fixed twice? pattern?)
- What's the QA escape rate post-release? (bugs found in production / total bugs)

**Dimension 2: Timing & Blocking**
- How long does QA take? (hours? days? weeks?)
- Does QA often block release? (% of stories? reasons?)
- Are QA blockers resolved quickly? (dev fixes next day? or stalls?)
- Does QA get the right test data? (do they find "test data gaps" that block testing?)

**Dimension 3: Coordination**
- Does QA Agent coordinate with Product Manager on AC clarity? (if AC ambiguous, does QA ask PM?)
- Does QA detect UX friction? (if yes, does QA escalate to UX Agent?)
- Does QA run mobile tests if mobile feature? (device matrix coverage?)
- Does QA validate edge cases per AC?

**Dimension 4: Accessibility & Performance**
- Does QA test accessibility? (keyboard nav? screen reader? contrast?)
- Does QA test performance? (load time? responsiveness?)
- Or are these delegated to separate agents/teams?

### Observation Checklist

For each story in QA phase, record:

```
Story: {KEY}
QA phase duration: {start-date} → {pass-date | fail-date}
QA verdict: [✅ PASSED | ❌ FAILED]

If passed:
- Bugs found: {count}
- Bug severity: {none | minor | major | critical}
- Test coverage: {estimate %}
- Accessibility tested? {yes | no | partial}
- Performance tested? {yes | no | partial}
- Mobile tested? {yes | no | N/A}

If failed:
- Bugs found: {count}
- Blocker bugs: {list}
- Non-blocker bugs: {list}
- Time to retest after fix: {days}
- Passed on retry? {yes | no}

Coordination:
- AC clarity issue encountered? {yes → {issue} | no}
- UX friction detected? {yes → {escalated to UX Agent? yes|no} | no}
- Test data gap? {yes → {issue} | no}
- Device coverage (mobile): {all devices | subset | N/A}

QA Escape:
- Story passed QA, escaped to production? {yes → {type of bug} | no}
```

### Decision Points for Formalization

After 2–3 sprints, answer:

1. **Testing depth:** Should QA Agent test:
   - All AC items thoroughly? (slower, but higher confidence)
   - Critical paths only? (faster, but risks regressions)
   - Dynamic? (simple features = critical paths; complex = thorough)

2. **Accessibility & Performance:** Should QA Agent test:
   - All features for accessibility? (WCAG 2.1 AA compliance check)
   - Only certain feature types? (UI features only? forms only?)
   - Delegated to separate accessibility agent?

3. **Coordination:** When QA finds UX friction:
   - Escalate immediately to UX Agent? (might delay release; but fixes UX debt)
   - File as tech debt? (ships now; UX Agent fixes later)
   - Escalate to TPM? (human decides on trade-off)

4. **Device coverage (mobile):** What's the minimum device matrix?
   - iOS: current version + 1 back? (e.g., iOS 17 + 16)
   - Android: same?
   - Different coverage for critical features?

---

## III. Deploy Agent — Observation Rules

### Current State (Governance Clarifications v1.0)
- Deploy Agent validates pre-release checklist
- Deploy Agent gates staging ↔ production parity
- Deploy Agent initiates staged rollout per Release Risk verdict
- Deploy Agent may NOT deploy to production without approval chain

### What to Observe

**Dimension 1: Deployment Frequency & Reliability**
- How often does Deploy Agent deploy to staging? (per story? per sprint? batch?)
- How often does Deploy Agent deploy to production? (per story? per release? per week?)
- What's the deployment failure rate? (% of deployments that require rollback?)
- How long do deployments take? (staging? production? including monitoring?)

**Dimension 2: Approval Chain**
- Does Deploy Agent get approval from TPM consistently? (always? sometimes? never?)
- Does Deploy Agent initiate staging deployment before TPM approval, or after?
- Are there bottlenecks in the approval chain? (TPM unavailable? human slow?)
- Does human approval ever get skipped? (if so, why? and should it be allowed?)

**Dimension 3: Checklist Discipline**
- Does Deploy Agent strictly follow pre-release checklist? (100%? or skips some items?)
- What items most often fail? (security sign-off? release notes? monitoring config?)
- Does failed checklist item delay release? (hours? days?) Or get waived?
- Are there checklist items that always pass (noise) vs. never pass (always blocker)?

**Dimension 4: Staging vs. Production**
- Does Deploy Agent catch issues in staging that would have hit production? (how many? what type?)
- Are staging deployments actually validated? (does Deploy Agent run post-deploy checks?)
- Does staging accurately mirror production? (config, secrets isolation, monitoring?)
- How often do issues slip from staging to production? (frequency? severity?)

**Dimension 5: Rollout Control**
- Does Deploy Agent follow staged rollout recommendations? (25% → 50% → 100%?)
- Does Deploy Agent skip stages under pressure? (if so, why? and should it be allowed?)
- Does Monitoring Agent validate metrics between stages?
- Can Deploy Agent execute rollback if needed? (is rollback procedure always available?)

### Observation Checklist

For each deployment (staging or production), record:

```
Deployment: {KEY} to {environment}
Date: {date}
Duration: {start-time} → {done-time} (total time)
Deploy verdict: [✅ SUCCESS | ❌ FAILED | ⚠️ PARTIAL]

Pre-release checklist (for production deployments):
- QA passed? {yes | no}
- Product Acceptance approved? {yes | no}
- Rollback available? {yes | no}
- Release notes ready? {yes | no}
- Monitoring enabled? {yes | no}
- Security sign-off? {yes | no | N/A}
- Compliance review? {yes | no | N/A}
- Analytics validated? {yes | no | N/A}
- Checklist complete? {yes | no}
- If incomplete, which items blocked? {list}

Approval chain (for production deployments):
- Release Risk verdict: {Green | Yellow | Red}
- TPM approval obtained? {yes | no}
- Deploy Agent initiated? {yes | no}
- Monitoring Agent validated parity? {yes | no}
- Human approval obtained? {yes | no | N/A}
- Total approval time: {hours}

Deployment execution:
- Deployment type: {standard | staged rollout | rollback}
- Staged rollout details: {% deployed | timing}
- Rollback executed? {yes | no}
- Rollback successful? {yes | no | partial}
- Issues detected during deployment? {none | list}
- Issues detected post-deployment? {none | list}
- Time to detection (if issue)? {minutes | hours}
- Time to resolution (if issue)? {hours | days}

Monitoring post-deployment:
- Monitoring Agent validated? {yes | no}
- Monitoring duration: {24h | 48h | other}
- Metrics checked: {crashes | API errors | auth issues | performance | analytics}
- Metrics healthy? {yes | no | {issues}}
```

### Decision Points for Formalization

After 2–3 sprints, answer:

1. **Timing of staging deployment:** Should Deploy Agent:
   - Deploy to staging immediately after code review? (fast feedback, but staging churns)
   - Wait for Monitoring Agent validation of previous release? (cleaner, but delays staging)
   - Batch staging deployments? (cost-efficient, but slower feedback)

2. **Checklist discipline:** Which checklist items should:
   - Always block? (security sign-off? release notes? rollback validation?)
   - Be waivable? (if so, who waives? TPM? human?)
   - Be automated (or "pass by default" if no applicable)?

3. **Staged rollout:** What should be the default rollout strategy?
   - 25% → 50% → 100%? (conservative)
   - 10% → 50% → 100%? (more conservative)
   - 50% → 100%? (faster)
   - Duration between stages? (6 hours? 24 hours? configurable?)

4. **Monitoring window:** How long should Monitoring Agent monitor?
   - 24 hours? (fast to Done, but low confidence)
   - 48 hours? (higher confidence, but slower releases)
   - Feature-dependent? (critical features = 48h; minor = 24h)

---

## IV. Release Risk Agent — Observation Rules

### Current State (Governance Clarifications v1.0)
- Release Risk Agent assesses each story ready for release
- Release Risk Agent gives verdict: Green | Yellow | Red
- Release Risk Agent may recommend staged rollout (Yellow)
- Release Risk Agent may block release (Red)

### What to Observe

**Dimension 1: Assessment Accuracy**
- When Release Risk Agent gives Green, do issues appear in production? (% of Greens that have incidents)
- When Release Risk Agent gives Red, is it always justified? (% of Reds that are overridden without issue)
- When Release Risk Agent gives Yellow, is staged rollout necessary? (% of Yellows that hit issues during rollout)

**Dimension 2: Assessment Speed**
- How long does Release Risk assessment take? (minutes? hours? days?)
- Is assessment fast enough not to block release? (assessment delay = release delay?)
- Does Release Risk Agent have enough information? (is AC clear? is QA result provided? is rollback plan documented?)

**Dimension 3: Risk Factors Considered**
- What risk factors cause Green → Yellow → Red transitions?
  - Story complexity? (code size? code churn? files changed?)
  - Feature type? (UI? API? data-sensitive? security-sensitive?)
  - Test coverage? (QA escape rate history?)
  - Dependencies? (database migration? backward compatibility?)
  - Mobile? (iOS + Android coordination needed?)
  - Rollback feasibility? (can we roll back if issue?)

**Dimension 4: False Positives / Negatives**
- Does Release Risk Agent recommend staged rollout when not needed? (all stories can deploy 100%?)
- Does Release Risk Agent miss risk factors? (story goes Green but has incident?)
- Are there story patterns where Release Risk assessment is consistent? (e.g., "all API changes get Yellow")

### Observation Checklist

For each story in Release Risk assessment, record:

```
Story: {KEY}
Release Risk assessment: {Green | Yellow | Red}
Assessment time: {minutes}
Verdict rationale: {why this verdict}

Risk factors considered:
- Story complexity: {low | medium | high}
- Feature type: {UI | API | data-access | security | mobile | other}
- QA escape rate for this type: {%}
- Dependencies: {none | list blocking items}
- Rollback feasibility: {easy | moderate | difficult | impossible}
- Mobile involved? {yes | no}
- Database migration? {yes | no}
- Breaking API change? {yes | no}

If Green:
- Proceed to production? {yes | no}
- If incident post-release, was risk factor missed? {yes → {factor} | no}

If Yellow:
- Staged rollout recommended: {% stages}
- Rollout timeline: {6h | 24h | other}
- Metrics to validate between stages: {list}
- Staged rollout executed? {yes | no}
- Did any stage fail? {yes → {what failed} | no}

If Red:
- Blocker reason: {specific risk}
- Can blocker be resolved? {yes | no | {conditions}}
- Is blocker overridden by TPM? {yes | no}
- If overridden, does issue occur? {yes | no}

Post-release outcome:
- Incident post-release? {yes → {severity} | no}
- Did Release Risk verdict align with outcome? {yes | no | partially}
```

### Decision Points for Formalization

After 2–3 sprints, answer:

1. **Risk factor weighting:** Which factors should strongly influence verdict?
   - Database migrations always Yellow/Red?
   - API breaking changes always Red?
   - Mobile features always Yellow?
   - UX-only features can be Green?

2. **Rollout strategy defaults:** When Release Risk recommends staged rollout, what should be:
   - Default stages? (25%-50%-100%?)
   - Default timing? (6h, 24h, 48h between stages?)
   - Default monitoring metrics? (crashes, errors, user engagement?)

3. **Override behavior:** When TPM overrides Release Risk Red verdict:
   - What factors justify override? (time pressure? low-risk assessment disagreement?)
   - How often should override succeed? (should be rare? or common?)
   - Should every override be logged and analyzed?

4. **Assessment speed:** Is Release Risk assessment fast enough?
   - Should it be automated (heuristics based on story metadata)?
   - Should it require human input from Release Risk Agent?
   - Can it be batched (assess multiple stories together)?

---

## V. Monitoring Agent — Observation Rules

### Current State (Governance Clarifications v1.0)
- Monitoring Agent monitors post-release for 24–48 hours
- Monitoring Agent checks: crashes, API errors, auth issues, performance, analytics
- Monitoring Agent transitions story to Stable → Done if clean
- Monitoring Agent escalates to Incident Agent if issues detected

### What to Observe

**Dimension 1: Detection Sensitivity**
- What types of issues does Monitoring Agent detect? (crashes? errors? performance degradation?)
- How fast are issues detected? (seconds? minutes? hours?)
- Are there patterns in missed issues? (certain metrics not monitored? certain issue types slip through?)

**Dimension 2: False Positives**
- Does Monitoring Agent flag issues that aren't real problems? (e.g., expected error spike due to batch job?)
- How often do alerts get ignored because they're noise?
- What false positive patterns exist?

**Dimension 3: Monitoring Duration**
- Is 24–48 hour monitoring window sufficient? (do issues appear after window?)
- Are there story types that need longer monitoring? (infrastructure changes? data migrations?)
- Is monitoring window configurable, or fixed?

**Dimension 4: Coordination with Incident Agent**
- When Monitoring Agent detects issue, does it properly escalate to Incident Agent?
- Does Incident Agent quickly determine root cause?
- How long from detection to resolution?

### Observation Checklist

For each released story, record:

```
Story: {KEY}
Monitoring start: {date-time}
Monitoring duration: {24h | 48h | custom}
Monitoring verdict: [✅ CLEAN | ⚠️ ISSUES DETECTED | ❌ CRITICAL INCIDENT]

Metrics monitored:
- Crashes: {rate, trend}
- API errors: {rate, error types, trend}
- Auth issues: {rate, type, trend}
- Performance: {P95 latency, trend}
- Analytics: {events firing? expected volume?}

If clean:
- All metrics normal? {yes | no}
- Transition to Stable → Done? {yes | no}

If issues detected:
- Issue severity: {minor | moderate | major}
- Issue type: {crash spike | error rate spike | performance | analytics gap | auth issues | other}
- Incident escalated? {yes | no}
- Time to detection: {seconds | minutes | hours}
- Time to resolution: {hours | days}
- Root cause (if determined): {cause}

Was issue predictable?
- Should Release Risk Agent have caught this? {yes | no | partial}
- Was monitoring metric configured pre-release? {yes | no}
- Should monitoring window have been longer? {yes | no}

Post-monitoring:
- Issue recurred after monitoring ended? {yes | no}
- Monitoring configuration improved? {yes | no}
```

### Decision Points for Formalization

After 2–3 sprints, answer:

1. **Monitoring window duration:** Should it be:
   - Fixed (24h or 48h for all)?
   - Feature-dependent (critical = 48h; minor = 24h)?
   - Configurable per release?

2. **Metrics to monitor:** Should Monitoring Agent check:
   - All stories for all metrics? (comprehensive but noisy)
   - Feature-specific metrics? (if feature adds new endpoint, monitor that endpoint only)
   - Baseline metrics only? (crashes, errors, performance)

3. **False positive handling:** When Monitoring Agent alerts:
   - Should it auto-validate? (e.g., "error spike due to batch job, expected")
   - Should it escalate to human for judgment?
   - Should it always escalate to Incident Agent?

---

## VI. Incident Agent — Observation Rules

### Current State (Governance Clarifications v1.0)
- Incident Agent classifies incidents SEV-1 through SEV-4
- Incident Agent identifies root cause, assesses rollback, generates postmortem

### What to Observe

**Dimension 1: Severity Accuracy**
- When Incident Agent classifies SEV-1, is immediate action required? (or overcautious?)
- When Incident Agent classifies SEV-4, is deferrable issue appropriate? (or under-assessed?)
- Are severity classifications consistent across incidents? (same type of issue always same severity?)

**Dimension 2: Root Cause Quality**
- Are root causes identified quickly? (minutes? hours? days?)
- Are root causes actually root (system-level) or symptom-level?
- Are patterns identified? (same root cause appearing multiple times?)

**Dimension 3: Rollback Assessment**
- When Incident Agent assesses rollback as viable, is it always feasible?
- When Incident Agent assesses rollback as infeasible, is rollback truly impossible?
- Are rollback timelines accurate?

**Dimension 4: Postmortem Quality**
- Are postmortems structured (root cause, prevention, learning)?
- Are prevention steps actually implemented?
- Do similar incidents recur (prevention step failing)?

### Observation Checklist

For each incident, record:

```
Incident: {story KEY or incident ID}
Severity: {SEV-1 | SEV-2 | SEV-3 | SEV-4}
Detection time: {date-time}
Resolution time: {date-time}
Duration: {minutes | hours | days}

Severity assessment:
- Was severity classification accurate? {yes | no | partially}
- Did severity match user impact? {yes | no}
- Was escalation action appropriate for severity? {yes | no}

Root cause identification:
- Root cause identified? {yes | no}
- Time to root cause: {hours}
- Root cause type: {code bug | configuration | dependency | design | data | other}
- Root cause accuracy: {system-level | symptom-level}
- Was pattern identified? (is this a repeat incident?)

Rollback assessment:
- Rollback assessed as: {viable | difficult | impossible}
- Was rollback actually executed? {yes | no}
- If executed, was it successful? {yes | no}
- Did rollback cause new issues? {yes | no}

Postmortem quality:
- Was postmortem completed? {yes | no}
- Postmortem sections: {root cause | timeline | impact | detection gap | resolution | prevention}
- Prevention steps defined? {yes | no}
- Prevention steps actionable? {yes | no}
- Are prevention steps tracked? {yes in tech debt | yes in monitoring | no}

Follow-up:
- Did similar incident recur? {yes | no | too early to tell}
- Time to recurrence (if applicable): {days}
- Was prevention step implemented? {yes | no}
```

### Decision Points for Formalization

After 2–3 sprints, answer:

1. **Severity quantification:** Define SEV-1/2/3/4 with quantitative thresholds:
   - SEV-1: X% user impact? All regions? Y minute duration?
   - SEV-2: Degradation % threshold?
   - SEV-3, SEV-4: How to distinguish?

2. **Postmortem speed:** Should postmortems be:
   - Completed immediately? (while memory fresh, but less data)
   - After 24h monitoring window? (more data, but details fade)
   - Weekly batch? (efficient, but details lost)

3. **Prevention tracking:** Should prevention steps be:
   - Always tracked in tech debt? (accountability, but inflates debt)
   - Only if critical? (focus on important prevention, but miss patterns)
   - Tracked in monitoring? (metrics-based prevention validation)

---

## VII. Summary: What to Collect During Observation Phase

**Per-story metrics:**
- Jira status transitions (timing)
- Agent comments (decisions, verdicts)
- Blocker reasons (when stories don't progress)
- Rework reasons (when stories return to previous stage)

**Per-agent metrics (Tier 2):**
- Assessment time (how long from input to verdict?)
- Verdict distribution (% Green/Yellow/Red or ✅/❌/⚠️)
- Accuracy (does verdict align with outcome?)
- Escalation rate (how often escalated to TPM or human?)
- Coordination (how do agents interact?)

**Cross-agent metrics:**
- Cycle time (Idea → Shipped)
- Rework loops (how many iterations before Done?)
- Bottleneck identification (which agent slows things most?)
- Conflict frequency (when do agents disagree?)

**Quality metrics:**
- QA escape rate (bugs post-release)
- Incident rate (severity distribution)
- Rollback frequency
- Deployment success rate

---

## VIII. End of Observation Phase: Data-Driven Formalization

After 2–3 sprints of observation using this framework, we will have:

1. **Real evidence** of what works (and what doesn't)
2. **Natural patterns** from Tier 2 agents (what they naturally do)
3. **Conflict points** (where agents disagree or deadlock)
4. **Timing data** (when each agent is needed)
5. **Decision thresholds** (quantitative criteria for verdicts)

This evidence will drive formalization of Tier 2 agent prompts in phase 2.

**Do not formalize Tier 2 prompts until this observation phase is complete.**
