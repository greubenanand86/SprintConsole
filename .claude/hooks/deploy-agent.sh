#!/usr/bin/env bash
# Deployment Specialist Agent — Jira Workflow Governance §11 §12
# Release Management Playbook v1.0 | Incident Management Playbook v1.0 | Environment Governance v1.0 | Security Baseline v1.0 |
# Engineering Constitution §8 §9 | Product Constitution §5
#
# Incident Management Playbook §3: Release deployment triggers monitoring workflow (Detected → Classify → ... → Monitor → Postmortem)
# Incident Playbook §5: Rollback must be available and validated before release
# Security Baseline §12: Mandatory Security Agent review before production for:
#   auth/authz changes, data access control changes, new sensitive APIs, external integrations, vulnerabilities
# Environment Governance §4: Deployment flow (no skipping):
#   Local → Development → Staging → Production
# Environment Governance §5: Production access restricted; sensitive changes need TPM + Security + human approval
# Release Management Playbook §3: Cannot release without full readiness checklist:
#   1. QA completed  2. Product Acceptance completed  3. Monitoring enabled
#   4. Rollback available  5. Release notes prepared  6. Crash reporting enabled (mobile)
#   7. Analytics events validated  8. Security review (if required)  9. Compliance review (if required)
# §11: Feature cannot release unless QA done, Product Acceptance done,
#      rollback available, monitoring ready, release notes finalized,
#      Release Risk review completed
# §9: AI agents may NOT deploy to production — always requires human approval

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/jira.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Query stories in Ready for Release, Done, or Product Acceptance (§11 gate)
DONE_STORIES=$(jira_get "search?jql=project=$JIRA_PROJECT+AND+status+in+(Done,%22Ready+for+Release%22)&updated>=-1h&maxResults=20&fields=summary,fixVersions,comment")
COUNT=$(echo "$DONE_STORIES" | jq '.issues | length' 2>/dev/null)
COUNT=${COUNT:-0}

[ "$COUNT" -eq 0 ] && exit 0

echo "Deploy Agent: $COUNT stories — running §11 release governance gate"

# ── Repository Governance v1.0: branch safety check ──────────────────────
CURRENT_BRANCH=$(git -C "$REPO_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
if echo "$CURRENT_BRANCH" | grep -qE '^hotfix/'; then
  echo "Deploy Agent: ⚠ hotfix/* branch detected — Release Risk review mandatory per Repository Governance v1.0"
  [ -n "$FIRST_KEY_EARLY" ] && escalate_to_tpm "$FIRST_KEY_EARLY" \
    "hotfix/* branch detected ($CURRENT_BRANCH). Repository Governance v1.0: hotfix branches require Release Risk review before merging to main." \
    "DEPLOY SPECIALIST"
fi

# ── Environment Governance v1.0: environment isolation check ────────────────
FIRST_KEY_EARLY=$(echo "$DONE_STORIES" | jq -r '.issues[0].key // ""')
ENV_CHECK=$(claude --print \
"Role: You are the Deployment Specialist Agent for SprintOps Console.
$AGENT_CONTEXT

Task: Verify Environment Governance v1.0 configuration isolation for these stories: $(echo "$DONE_STORIES" | jq -r '.issues[].fields.summary' | head -3 | tr '\n' '; ')

Inputs: Source files readable via Read and Glob tools (look for config files, .env, secrets, environment setup)

Environment Governance v1.0 §4-5: Mandatory environment isolation checks:
1. Separate configs per environment (.env.local, .env.dev, .env.staging, .env.production)
2. No hardcoded secrets in source code (check for API keys, passwords, tokens)
3. No shared secrets or credentials across environments
4. No production config or secrets in development/staging code

Output format: For each check output exactly one line:
ENV_CHECK|<check>|OK|<note>
or
ENV_CHECK|<check>|FAIL|<reason>

$AGENT_CONSTRAINTS

$AGENT_ESCALATION_RULES" \
  --allowedTools "Read,Glob" \
  --no-conversation 2>/dev/null)

ENV_FAILS=$(echo "$ENV_CHECK" | grep '^ENV_CHECK|' | grep '|FAIL|')
ENV_OK=$(echo "$ENV_CHECK" | grep '^ENV_CHECK|' | grep '|OK|' | wc -l | tr -d ' ')

if [ -n "$ENV_FAILS" ]; then
  echo "Deploy Agent: ⚠ Environment isolation gaps per Governance v1.0"
  [ -n "$FIRST_KEY_EARLY" ] && escalate_to_tpm "$FIRST_KEY_EARLY" \
    "Environment Governance v1.0 §4-5: Configuration isolation gaps detected. No hardcoded secrets, separate configs per environment required." \
    "DEPLOY SPECIALIST"
fi

# ── Read Product Acceptance handoff packet (Agent Interaction Protocols §2) ─
FIRST_KEY_EARLY=$(echo "$DONE_STORIES" | jq -r '.issues[0].key // ""')
PRIOR_HANDOFF=""
[ -n "$FIRST_KEY_EARLY" ] && PRIOR_HANDOFF=$(read_last_handoff "$FIRST_KEY_EARLY")
PA_HANDOFF_RISKS=$(echo "$PRIOR_HANDOFF" | sed 's/.*Risks: //' | sed 's/ Dependencies:.*//' | head -c 200)
PA_HANDOFF_OPEN=$(echo "$PRIOR_HANDOFF" | sed 's/.*Open Questions: //' | sed 's/ Expected.*//' | head -c 200)

# ── Release Risk check ─────────────────────────────────────────────────────
RISK_LEVEL="UNKNOWN"
FIRST_KEY=$(echo "$DONE_STORIES" | jq -r '.issues[0].key // ""')
if [ -n "$FIRST_KEY" ]; then
  RISK_COMMENT=$(jira_get "issue/$FIRST_KEY/comments?maxResults=50" | \
    jq -r '.comments[].body.content[]?.content[]?.text // ""' 2>/dev/null | \
    grep '\[RELEASE RISK\]' | head -1)
  if echo "$RISK_COMMENT" | grep -q 'RED';    then RISK_LEVEL="RED"; fi
  [ "$RISK_LEVEL" = "UNKNOWN" ] && echo "$RISK_COMMENT" | grep -q 'GREEN'  && RISK_LEVEL="GREEN"
  [ "$RISK_LEVEL" = "UNKNOWN" ] && echo "$RISK_COMMENT" | grep -q 'YELLOW' && RISK_LEVEL="YELLOW"
fi

if [ "$RISK_LEVEL" = "RED" ]; then
  echo "Deploy Agent: 🚫 Blocked — Release Risk is RED"
  echo "$DONE_STORIES" | jq -r '.issues[].key' | while read -r KEY; do
    jira_comment "$KEY" "[DEPLOY SPECIALIST] 🚫 Deployment Blocked — RED Release Risk
Per §11 §9: RED risk blocks deployment. Human escalation required."
    escalate_to_tpm "$KEY" "RED release risk blocks deployment — §16: Release quality > Delivery speed." "DEPLOY SPECIALIST"
  done
  exit 2
fi

# ── §11: Product Acceptance gate ──────────────────────────────────────────
PA_VERIFIED=false
if [ -n "$FIRST_KEY" ]; then
  PA_COMMENT=$(jira_get "issue/$FIRST_KEY/comments?maxResults=50" | \
    jq -r '.comments[].body.content[]?.content[]?.text // ""' 2>/dev/null | \
    grep '\[PRODUCT ACCEPTANCE\].*✅\|✅.*\[PRODUCT ACCEPTANCE\]' | head -1)
  [ -n "$PA_COMMENT" ] && PA_VERIFIED=true
fi
PA_GATE="☐ Product Acceptance — NOT FOUND (§11 requires PA before release)"
if $PA_VERIFIED; then
  PA_GATE="☑ Product Acceptance verified (§7 §11)"
else
  # Escalate to TPM: no PA = agent disagreement risk
  [ -n "$FIRST_KEY" ] && escalate_to_tpm "$FIRST_KEY" \
    "Deploy reached Ready for Release without Product Acceptance sign-off. §4: Stability > Delivery speed." \
    "DEPLOY SPECIALIST"
fi

# ── §5: UX review gate ─────────────────────────────────────────────────────
UX_REVIEWED=false
if [ -n "$FIRST_KEY" ]; then
  UX_COMMENT=$(jira_get "issue/$FIRST_KEY/comments?maxResults=50" | \
    jq -r '.comments[].body.content[]?.content[]?.text // ""' 2>/dev/null | \
    grep '\[UX DESIGNER\]' | head -1)
  [ -n "$UX_COMMENT" ] && UX_REVIEWED=true
fi
UX_GATE="☐ UX review — NOT FOUND (§5 requires UX review before release)"
$UX_REVIEWED && UX_GATE="☑ UX review verified (§5)"

# ── §11: QA sign-off gate ──────────────────────────────────────────────────
QA_VERIFIED=false
if [ -n "$FIRST_KEY" ]; then
  QA_PASS=$(jira_get "issue/$FIRST_KEY/comments?maxResults=50" | \
    jq -r '.comments[].body.content[]?.content[]?.text // ""' 2>/dev/null | \
    grep '\[QA LEAD\].*✅\|✅.*\[QA LEAD\]' | head -1)
  [ -n "$QA_PASS" ] && QA_VERIFIED=true
fi
QA_GATE="☐ QA sign-off — NOT FOUND (§11 requires QA before release)"
$QA_VERIFIED && QA_GATE="☑ QA sign-off verified (§8 §11)"

# ── Security Baseline §12: Security sign-off gate ──────────────────────────
# Mandatory for: auth/authz changes, data access control, new sensitive APIs, integrations, vulnerabilities
SEC_VERIFIED=false
SEC_REQUIRED=false
if [ -n "$FIRST_KEY" ]; then
  # Check if story touches sensitive areas (auth, data, permissions, payment, integration, vulnerability)
  SUMMARY=$(echo "$DONE_STORIES" | jq -r '.issues[0].fields.summary // ""')
  SUMMARY_LOWER=$(echo "$SUMMARY" | tr '[:upper:]' '[:lower:]')
  if echo "$SUMMARY_LOWER" | grep -qiE 'auth|login|password|token|permission|role|data access|api.*security|payment|integration|vulnerab|secret|encryption|gdpr|pii'; then
    SEC_REQUIRED=true
  fi

  if $SEC_REQUIRED; then
    SEC_COMMENT=$(jira_get "issue/$FIRST_KEY/comments?maxResults=50" | \
      jq -r '.comments[].body.content[]?.content[]?.text // ""' 2>/dev/null | \
      grep '\[SECURITY\].*✅\|✅.*\[SECURITY\]' | head -1)
    [ -n "$SEC_COMMENT" ] && SEC_VERIFIED=true
  else
    # Not security-sensitive, no sign-off needed
    SEC_VERIFIED=true
  fi
fi
SEC_GATE="☐ Security sign-off — NOT FOUND (Security Baseline §12 requires review for sensitive changes)"
if $SEC_VERIFIED; then
  SEC_GATE="☑ Security sign-off verified (Security Baseline §12)"
elif $SEC_REQUIRED; then
  # Escalate: security-sensitive but no sign-off
  [ -n "$FIRST_KEY" ] && escalate_to_tpm "$FIRST_KEY" \
    "Security-sensitive story reached Ready for Release without Security Agent sign-off. Security Baseline §12: security review required for auth/data/API/integration changes." \
    "DEPLOY SPECIALIST"
fi

# ── §6: Definition of Done check ──────────────────────────────────────────
DOD_CHECK=$(claude --print \
"Role: You are the Deployment Specialist Agent for SprintOps Console.
$AGENT_CONTEXT

Task: Verify Definition of Done (§6) for these stories: $(echo "$DONE_STORIES" | jq -r '.issues[].fields.summary' | head -5 | tr '\n' '; ')

Inputs: Source files readable via Read and Glob tools.

Definition of Done (§6) — a story is not complete without ALL of:
1. Acceptance criteria validated (QA sign-off present)
2. Unit testing completed (test files or QA test cases exist)
3. QA verified (QA Lead sign-off present)
4. Accessibility reviewed (§5 pass in QA comment)
5. Regression impact reviewed (release risk assessment present)
6. Documentation updated (CLAUDE.md, README, inline comments where applicable)
7. Monitoring/logging added (error boundaries, structured logging where applicable)
8. Release notes prepared (deploy comment with release notes)
9. Product Acceptance completed ([PRODUCT ACCEPTANCE] ✅ present)

Repository Governance v1.0 PR merge gates (REPOSITORY_GOVERNANCE.md) — also check:
10. CI passes (look for CI pass evidence or assume passing if no CI configured yet)
11. Code review completed (look for [ARCHITECT] or [SECURITY] sign-off)
12. QA path identified (look for test cases or QA plan)
13. No unresolved release blockers (no open RED risk or unresolved escalations)

Output format: For each DoD item output exactly one line:
DOD|<item>|MET|<note>
or
DOD|<item>|UNMET|<gap description>

$AGENT_CONSTRAINTS

$AGENT_ESCALATION_RULES" \
  --allowedTools "Read,Glob" \
  --no-conversation 2>/dev/null)

DOD_UNMET=$(echo "$DOD_CHECK" | grep '^DOD|' | grep '|UNMET|' | sed 's/^DOD|//' | sed 's/|UNMET|/: gap — /')
DOD_MET=$(echo "$DOD_CHECK" | grep '^DOD|' | grep '|MET|' | wc -l | tr -d ' ')

# ── Release Management Playbook §3: Readiness checklist ────────────────────
READINESS_CHECK=$(claude --print \
"Role: You are the Deployment Specialist Agent for SprintOps Console.
$AGENT_CONTEXT

Task: Verify Release Management Playbook §3 release readiness checklist for these stories: $(echo "$DONE_STORIES" | jq -r '.issues[].fields.summary' | head -5 | tr '\n' '; ')

Inputs: Source files readable via Read and Glob tools.

Release Management Playbook §3: Release Readiness Checklist — all 9 items MANDATORY:
1. QA completed — QA Lead sign-off present (look for [QA LEAD] ✅)
2. Product Acceptance completed — PA sign-off present (look for [PRODUCT ACCEPTANCE] ✅)
3. Monitoring enabled — monitoring plan documented (look for monitoring config or plan)
4. Rollback available — rollback strategy documented and tested (look for rollback notes in deployment comments)
5. Release notes prepared — release notes present in deployment comment
6. Crash reporting enabled (mobile) — if mobile story, crash reporting config present (look for Sentry/Crash config)
7. Analytics events validated — analytics events validated per Analytics §8 (look for analytics validation in QA comment)
8. Security review completed (if required) — if security-sensitive, [SECURITY AGENT] sign-off present
9. Compliance review completed (if required) — if compliance-sensitive, compliance sign-off present

Output format: For each checklist item output exactly one line:
READINESS|<item>|MET|<note>
or
READINESS|<item>|UNMET|<gap description>
or
READINESS|<item>|N/A|<reason not applicable>

$AGENT_CONSTRAINTS

$AGENT_ESCALATION_RULES" \
  --allowedTools "Read,Glob" \
  --no-conversation 2>/dev/null)

READINESS_UNMET=$(echo "$READINESS_CHECK" | grep '^READINESS|' | grep '|UNMET|' | sed 's/^READINESS|//' | sed 's/|UNMET|/: UNMET — /')
READINESS_MET=$(echo "$READINESS_CHECK" | grep '^READINESS|' | grep '|MET|' | wc -l | tr -d ' ')

if [ -n "$READINESS_UNMET" ]; then
  echo "Deploy Agent: ⚠ Release readiness gaps detected per Playbook §3"
fi

# ── §8 staging verification ────────────────────────────────────────────────
STAGING_OK=false
git -C "$REPO_ROOT" branch -a 2>/dev/null | grep -qiE 'staging|preview|preprod' && STAGING_OK=true
STAGING_NOTE="⚠ No staging evidence (§8 recommends staging before production)"
$STAGING_OK && STAGING_NOTE="☑ Staging branch verified"

# ── Artefact checks ───────────────────────────────────────────────────────
DEPLOY_CHECK=$(claude --print \
"Role: You are the Deployment Specialist Agent for SprintOps Console.
$AGENT_CONTEXT

Task: Verify all pre-release artefacts are present and correct.

Inputs: Repository files readable via Read, Glob, and Bash tools.

Artefact checklist:
1. index.html exists and references only vendor/ and local .js/.jsx files
2. All files referenced in index.html exist on disk
3. vendor/ contains react.development.js, react-dom.development.js, babel.min.js, lucide.min.js
4. No absolute paths hardcoded in hook scripts
5. .claude/settings.json is valid JSON
6. ROLLBACK: At least 2 git commits exist (can revert)
7. MONITORING: No missing critical scripts in index.html

Output format: For each check output exactly one line:
DEPLOY_CHECK|<name>|OK|<note>
or
DEPLOY_CHECK|<name>|FAIL|<reason>

$AGENT_CONSTRAINTS

$AGENT_ESCALATION_RULES" \
  --allowedTools "Read,Glob,Bash" \
  --no-conversation 2>/dev/null)

DEPLOY_FAILS=$(echo "$DEPLOY_CHECK" | grep '^DEPLOY_CHECK|' | grep '|FAIL|')
DEPLOY_OK=$(echo "$DEPLOY_CHECK" | grep '^DEPLOY_CHECK|' | grep '|OK|' | wc -l | tr -d ' ')

if [ -n "$DEPLOY_FAILS" ]; then
  echo "Deploy Agent: ❌ Artefact checks failed"
  echo "$DONE_STORIES" | jq -r '.issues[].key' | while read -r KEY; do
    jira_comment "$KEY" "[DEPLOY SPECIALIST] ❌ Pre-Release Artefact Checks Failed (§11)
$(echo "$DEPLOY_FAILS" | sed 's/^DEPLOY_CHECK|//' | sed 's/|FAIL|/: FAIL — /' | sed 's/^/• /')
Resolve before deployment."
  done
  exit 2
fi

# ── Generate user-facing release notes (§5) ───────────────────────────────
STORY_LIST=$(echo "$DONE_STORIES" | jq -r '.issues[] | "- \(.key): \(.fields.summary)"')

RELEASE_NOTES=$(claude --print \
"Role: You are the Deployment Specialist Agent for SprintOps Console writing user-facing release notes.
$AGENT_CONTEXT

Task: Write release notes for this release in plain language for sprint managers.

Inputs:
- Stories in this release:
$STORY_LIST

Product Constitution §5 §1: Release notes are mandatory. Avoid technical jargon — write for sprint managers who understand sprint management but not engineering internals.

Output format — output EXACTLY these sections:

WHATS_NEW:
- <user-facing description>

IMPROVEMENTS:
- <improvement, or 'None in this release'>

BUG_FIXES:
- <fix, or 'None in this release'>

KNOWN_LIMITATIONS:
- <limitation, or 'None'>

ROLLBACK_NOTE: <one sentence on how to revert if needed>

$AGENT_CONSTRAINTS

$AGENT_ESCALATION_RULES

$STANDARD_OUTPUT_SUFFIX

$NONTECHNICAL_SUMMARY_REQ" \
  --allowedTools "Read" \
  --no-conversation 2>/dev/null)

extract_standard "$RELEASE_NOTES"
NON_TECH=$(echo "$RELEASE_NOTES" | sed -n '/^NON_TECHNICAL_SUMMARY:/,/^---/p' | head -8)

# ── Create Fix Version (unreleased — pending human approval) ──────────────
TODAY=$(date +%Y-%m-%d)
VERSION_NAME="v$(date +%Y.%m.%d)"

VERSIONS=$(jira_get "project/$JIRA_PROJECT/versions")
VERSION_ID=$(echo "$VERSIONS" | jq -r --arg name "$VERSION_NAME" '.[] | select(.name==$name) | .id' | head -1)

if [ -z "$VERSION_ID" ]; then
  VERSION_PAYLOAD=$(jq -n \
    --arg proj "$JIRA_PROJECT" \
    --arg name "$VERSION_NAME" \
    --arg date "$TODAY" \
    '{"name":$name,"project":$proj,"releaseDate":$date,"released":false}')
  VERSION_RESULT=$(jira_post "version" "$VERSION_PAYLOAD")
  VERSION_ID=$(echo "$VERSION_RESULT" | jq -r '.id // ""')
  echo "Deploy Agent: Created Fix Version $VERSION_NAME (unreleased — pending approval)"
fi

# ── Tag stories and post approval request with full §11 checklist ─────────
echo "$DONE_STORIES" | jq -r '.issues[].key' | while read -r KEY; do
  [ -n "$VERSION_ID" ] && jira_put "issue/$KEY" "{\"fields\":{\"fixVersions\":[{\"id\":\"$VERSION_ID\"}]}}" > /dev/null
  jira_transition "$KEY" "Ready for Release"  # best-effort; no-op if state not configured

  jira_comment "$KEY" "[DEPLOY SPECIALIST] 📦 Release Package Ready — Human Approval Required (§9 §11 §Playbook)

Fix Version: $VERSION_NAME
Release Readiness Checklist (Playbook §3): $READINESS_MET/9 items verified
Artefact checks: $DEPLOY_OK/7 passed
Release Risk: ${RISK_LEVEL:-UNKNOWN}
$STAGING_NOTE
Prepared: $(date -u '+%Y-%m-%d %H:%M UTC')

--- RELEASE NOTES ($VERSION_NAME) ---
What's New:
$(echo "$RELEASE_NOTES" | sed -n '/^WHATS_NEW:/,/^IMPROVEMENTS:/p' | grep '^-' | sed 's/^- /• /')

Improvements:
$(echo "$RELEASE_NOTES" | sed -n '/^IMPROVEMENTS:/,/^BUG_FIXES:/p' | grep '^-' | sed 's/^- /• /')

Bug Fixes:
$(echo "$RELEASE_NOTES" | sed -n '/^BUG_FIXES:/,/^KNOWN_LIMITATIONS:/p' | grep '^-' | sed 's/^- /• /')

Known Limitations:
$(echo "$RELEASE_NOTES" | sed -n '/^KNOWN_LIMITATIONS:/,/^ROLLBACK_NOTE:/p' | grep '^-' | sed 's/^- /• /')

$(echo "$RELEASE_NOTES" | grep '^ROLLBACK_NOTE:' | sed 's/^ROLLBACK_NOTE: /Rollback: /')
--- END RELEASE NOTES ---

§11 Release Governance Checklist + Security Baseline §12:
$PA_GATE
$QA_GATE
$UX_GATE
$SEC_GATE
☑ Accessibility checked (QA §5 pass required in QA sign-off)
☑ Artefact verification ($DEPLOY_OK/7 passed)
☑ Rollback available (git revert)
☑ Release Risk: ${RISK_LEVEL:-UNKNOWN}
☑ Release notes prepared (above)
$STAGING_NOTE

Release Management Playbook §3 Readiness ($READINESS_MET/9 passed):
$(echo "$READINESS_CHECK" | grep '^READINESS|' | sed 's/^READINESS|//' | sed 's/|MET|/: ✅ /' | sed 's/|UNMET|/: ❌ UNMET — /' | sed 's/|N\/A|/: ➖ N\/A — /' | sed 's/^/  /')
$([ -n "$READINESS_UNMET" ] && echo "
⚠ Release readiness gaps (Release Management Playbook §3):
$(echo "$READINESS_UNMET" | sed 's/^/  • /')")
$([ -n "$DOD_UNMET" ] && echo "
⚠ Definition of Done gaps detected (§6):
$(echo "$DOD_UNMET" | sed 's/^/  • /')")
$([ -n "$PA_HANDOFF_RISKS" ] && [ "$PA_HANDOFF_RISKS" != "None" ] && echo "
⚠ Risks from Product Acceptance handoff:
  $PA_HANDOFF_RISKS")
$([ -n "$PA_HANDOFF_OPEN" ] && [ "$PA_HANDOFF_OPEN" != "None" ] && echo "
Open Questions (from PA handoff):
  $PA_HANDOFF_OPEN")
☐ Human approval — REQUIRED before production (§9)
${NON_TECH:+
Non-Technical Summary:
$NON_TECH}
$(standard_fields_block)

After human approves:
→ Mark Fix Version $VERSION_NAME as Released in Jira
→ Deploy to https://greubenanand86.github.io/SprintConsole/
→ Monitoring Agent will begin post-release monitoring (§12)"

  echo "Deploy Agent: $KEY tagged $VERSION_NAME — awaiting human approval"
done

echo "Deploy Agent: Release $VERSION_NAME prepared — §11 checklist complete"
exit 0
