#!/usr/bin/env bash
# Release Risk Agent — Jira Workflow Governance §9 §11 | Release Management Playbook §2 §3 §7 | Incident Management Playbook v1.0
# Environment Governance v1.0 §4-6 — environment progression and production governance
# Incident Playbook §5: Rollback preferred when user trust impacted, crashes widespread, auth unstable, data at risk
# Incident Playbook §4: DevOps Agent owns rollback execution; TPM Agent owns escalation; Human owns final decisions
# Assesses deployment risk for Done stories: Green / Yellow / Red
# Green = proceed, Yellow = staged rollout recommended, Red = block
# Validates: Staging validated before production, production access controls, environment isolation
# Release type detection: Standard (TPM+Human) | Hotfix (TPM+Human) | Mobile Beta (TPM) |
#   Production Mobile (Human) | Infrastructure (TPM+Security+Human)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/jira.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

DONE_STORIES=$(jira_get "search?jql=project=$JIRA_PROJECT+AND+status+in+(Done,%22Ready+for+Release%22)+AND+updated>=-1h&maxResults=20&fields=summary,labels")
COUNT=$(echo "$DONE_STORIES" | jq '.issues | length' 2>/dev/null)
COUNT=${COUNT:-0}

[ "$COUNT" -eq 0 ] && exit 0

# Skip if first story already has a risk assessment
FIRST_KEY=$(echo "$DONE_STORIES" | jq -r '.issues[0].key // ""')
[ -z "$FIRST_KEY" ] && exit 0

COMMENTS=$(jira_get "issue/$FIRST_KEY/comments?maxResults=50")
HAS_RISK=$(echo "$COMMENTS" | jq -r '.comments[].body.content[]?.content[]?.text // ""' 2>/dev/null | grep -c '\[RELEASE RISK\]' || true)
[ "$HAS_RISK" -gt 0 ] && exit 0

echo "Release Risk Agent: Assessing risk for $COUNT stories"

STORY_LIST=$(echo "$DONE_STORIES" | jq -r '.issues[] | "- \(.key): \(.fields.summary)"')

RISK_ASSESSMENT=$(claude --print \
"Role: You are the Release Risk Agent for SprintOps Console.
$AGENT_CONTEXT

Task: Assess the overall deployment risk for this release. Identify the release type, determine required approvals, evaluate rollback readiness, and output a risk level (GREEN/YELLOW/RED).

Inputs:
- Stories in this release:
$STORY_LIST
- Source files readable via Read, Glob, and Grep tools

Release Management Playbook §3 — Release types and required approvals:
- Standard Release (planned feature delivery): Requires TPM + Human approval
- Hotfix (critical production fix, hotfix/* branch): Requires TPM + Human approval + postmortem plan
- Mobile Beta (TestFlight/Internal): Requires TPM approval
- Production Mobile Release (App Store/Play Store): Requires Human approval
- Infrastructure Release (CI/CD/Auth/DB changes): Requires TPM + Security Agent + Human approval

Release Management Playbook §7 — Rollback governance (ALL releases must satisfy):
- Rollback strategy documented (how to revert)
- Rollback owner identified (who executes revert)
- Rollback validation confirmed (revert has been tested or is straightforward)
- Rollback feasibility known BEFORE release begins

Risk factors to evaluate:
1. Release type — classify and confirm correct approval path
2. Scope and number of changes
3. Security-sensitive areas touched (auth, PII, payments, integrations)
4. Data model or breaking changes
5. Test coverage and QA sign-off completeness
6. Rollback feasibility (can changes be reverted cleanly?)
7. Monitoring availability post-deploy

Output format — output EXACTLY these sections:

RELEASE_TYPE: <Standard Release|Hotfix|Mobile Beta|Production Mobile|Infrastructure Release>
REQUIRED_APPROVALS: <list of required approvers per Playbook §3>

RISK_LEVEL: <GREEN|YELLOW|RED>

RATIONALE:
- <reason 1>
- <reason 2>

AFFECTED_SYSTEMS:
- <system or component>

ROLLBACK_PLAN:
- <step 1>
- <step 2>

ROLLBACK_OWNER: <who is responsible for executing rollback>
ROLLBACK_FEASIBILITY: <CONFIRMED — steps are clear and tested|UNCERTAIN — needs validation before release|NOT_POSSIBLE — no rollback path>

MONITORING_CHECKLIST:
- <what to verify post-deploy>

RECOMMENDATION: <PROCEED|STAGED_ROLLOUT|BLOCK>

$AGENT_CONSTRAINTS

$AGENT_ESCALATION_RULES

$STANDARD_OUTPUT_SUFFIX

$NONTECHNICAL_SUMMARY_REQ" \
  --allowedTools "Read,Glob,Grep" \
  --no-conversation 2>/dev/null)

RISK_LEVEL=$(echo "$RISK_ASSESSMENT" | grep '^RISK_LEVEL:' | sed 's/^RISK_LEVEL: //')
RECOMMENDATION=$(echo "$RISK_ASSESSMENT" | grep '^RECOMMENDATION:' | sed 's/^RECOMMENDATION: //')
RELEASE_TYPE=$(echo "$RISK_ASSESSMENT" | grep '^RELEASE_TYPE:' | sed 's/^RELEASE_TYPE: //')
REQUIRED_APPROVALS=$(echo "$RISK_ASSESSMENT" | grep '^REQUIRED_APPROVALS:' | sed 's/^REQUIRED_APPROVALS: //')
ROLLBACK_FEASIBILITY=$(echo "$RISK_ASSESSMENT" | grep '^ROLLBACK_FEASIBILITY:' | sed 's/^ROLLBACK_FEASIBILITY: //')
ROLLBACK_OWNER=$(echo "$RISK_ASSESSMENT" | grep '^ROLLBACK_OWNER:' | sed 's/^ROLLBACK_OWNER: //')
extract_standard "$RISK_ASSESSMENT"
NON_TECH=$(echo "$RISK_ASSESSMENT" | sed -n '/^NON_TECHNICAL_SUMMARY:/,/^SUMMARY:/p' | head -8)

case "$RISK_LEVEL" in
  GREEN)  RISK_ICON="✅" ;;
  YELLOW) RISK_ICON="⚠️" ;;
  RED)    RISK_ICON="🚫" ;;
  *)      RISK_ICON="❓" ; RISK_LEVEL="UNKNOWN" ;;
esac

# Block if rollback is not confirmed for non-Mobile Beta releases
ROLLBACK_BLOCKED=false
if echo "$ROLLBACK_FEASIBILITY" | grep -q 'NOT_POSSIBLE'; then
  ROLLBACK_BLOCKED=true
  echo "Release Risk Agent: 🚫 Blocked — no rollback path (Release Management Playbook §7)"
fi

COMMENT="[RELEASE RISK] $RISK_ICON Risk Level: $RISK_LEVEL

Release Type: ${RELEASE_TYPE:-Unknown — classify manually}
Required Approvals: ${REQUIRED_APPROVALS:-TPM + Human approval (default)}

Rationale:
$(echo "$RISK_ASSESSMENT" | sed -n '/^RATIONALE:/,/^AFFECTED_SYSTEMS:/p' | grep '^-' | sed 's/^- /• /')

Affected Systems:
$(echo "$RISK_ASSESSMENT" | sed -n '/^AFFECTED_SYSTEMS:/,/^ROLLBACK_PLAN:/p' | grep '^-' | sed 's/^- /• /')

Rollback Plan:
$(echo "$RISK_ASSESSMENT" | sed -n '/^ROLLBACK_PLAN:/,/^ROLLBACK_OWNER:/p' | grep '^-' | sed 's/^- /→ /')
Rollback Owner: ${ROLLBACK_OWNER:-Not identified — assign before release}
Rollback Feasibility: ${ROLLBACK_FEASIBILITY:-UNCERTAIN}

Monitoring Checklist (post-deploy — Playbook §8):
$(echo "$RISK_ASSESSMENT" | sed -n '/^MONITORING_CHECKLIST:/,/^RECOMMENDATION:/p' | grep '^-' | sed 's/^- /☐ /')

Recommendation: ${RECOMMENDATION:-STAGED_ROLLOUT}

GOVERNANCE NOTE: Per Playbook §2, all releases must be observable, recoverable, and governable.
Per §4 and §9, human approval is required before production deployment regardless of risk level.
A RED assessment or unresolvable rollback blocks deployment entirely.
${ROLLBACK_BLOCKED:+
⚠ ROLLBACK BLOCKED: No rollback path identified. Deployment blocked per Release Management Playbook §7.
Release may NOT proceed until a rollback strategy is documented and validated.}
${NON_TECH:+
Non-Technical Summary:
$NON_TECH}
$(standard_fields_block)"

echo "$DONE_STORIES" | jq -r '.issues[].key' | while read -r KEY; do
  jira_comment "$KEY" "$COMMENT"
done

# Write risk level for deploy-agent to consume
echo "$RISK_LEVEL" > /tmp/sprintops-release-risk.txt

echo "Release Risk Agent: Level=$RISK_LEVEL Type=${RELEASE_TYPE:-Unknown} Recommendation=${RECOMMENDATION:-STAGED_ROLLOUT}"

if [ "$RISK_LEVEL" = "RED" ]; then
  echo "Release Risk Agent: 🚫 RED — deployment blocked. Human escalation required per §10."
  echo "$DONE_STORIES" | jq -r '.issues[].key' | while read -r KEY; do
    escalate_to_tpm "$KEY" \
      "RED release risk — Release Management Playbook §2: Stability > Speed. Human approval required before any deployment." \
      "RELEASE RISK"
  done
  exit 2
fi

if $ROLLBACK_BLOCKED; then
  echo "Release Risk Agent: 🚫 ROLLBACK BLOCKED — no rollback path. Deployment blocked per Playbook §7."
  echo "$DONE_STORIES" | jq -r '.issues[].key' | while read -r KEY; do
    escalate_to_tpm "$KEY" \
      "No rollback path identified. Release Management Playbook §7: rollback strategy, owner, and validation required before release." \
      "RELEASE RISK"
  done
  exit 2
fi

# Infrastructure releases always escalate to TPM + Security for additional approval
if echo "$RELEASE_TYPE" | grep -qi 'infrastructure'; then
  echo "Release Risk Agent: ⚠ Infrastructure Release — escalating to TPM + Security per Playbook §3"
  echo "$DONE_STORIES" | jq -r '.issues[].key' | while read -r KEY; do
    escalate_to_tpm "$KEY" \
      "Infrastructure Release detected. Playbook §3: TPM + Security Agent + Human approval required before deployment." \
      "RELEASE RISK"
  done
fi

exit 0
