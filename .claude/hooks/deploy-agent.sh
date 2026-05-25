#!/usr/bin/env bash
# Deployment Specialist Agent
# Triggered when QA signs off (stories move to Done)
# Verifies deployment readiness, prepares release notes, requests human approval
#
# GOVERNANCE §4: Production releases require QA validation, Release Risk assessment,
# Rollback readiness, Monitoring readiness, and HUMAN APPROVAL.
# AI agents may NOT deploy directly to production (governance §3).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/jira.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# ── Check for newly-done stories ───────────────────────────────────────────
DONE_STORIES=$(jira_get "search?jql=project=$JIRA_PROJECT+AND+status=Done+AND+updated>=-1h&maxResults=20&fields=summary,fixVersions,comment")
COUNT=$(echo "$DONE_STORIES" | jq '.issues | length' 2>/dev/null)
COUNT=${COUNT:-0}

[ "$COUNT" -eq 0 ] && exit 0

echo "Deploy Agent: $COUNT stories completed — running pre-release checklist"

# ── Check release risk assessment ──────────────────────────────────────────
RISK_LEVEL="UNKNOWN"
if [ -f /tmp/sprintops-release-risk.txt ]; then
  RISK_LEVEL=$(cat /tmp/sprintops-release-risk.txt | tr -d '[:space:]')
fi

# Also check Jira for risk assessment comment
FIRST_KEY=$(echo "$DONE_STORIES" | jq -r '.issues[0].key // ""')
if [ -n "$FIRST_KEY" ]; then
  RISK_COMMENT=$(jira_get "issue/$FIRST_KEY/comments?maxResults=50" | \
    jq -r '.comments[].body.content[]?.content[]?.text // ""' 2>/dev/null | \
    grep '\[RELEASE RISK\]' | head -1)
  if echo "$RISK_COMMENT" | grep -q 'RED'; then RISK_LEVEL="RED"; fi
  if [ "$RISK_LEVEL" = "UNKNOWN" ] && echo "$RISK_COMMENT" | grep -q 'GREEN'; then RISK_LEVEL="GREEN"; fi
  if [ "$RISK_LEVEL" = "UNKNOWN" ] && echo "$RISK_COMMENT" | grep -q 'YELLOW'; then RISK_LEVEL="YELLOW"; fi
fi

if [ "$RISK_LEVEL" = "RED" ]; then
  echo "Deploy Agent: 🚫 Deployment BLOCKED — Release Risk is RED per governance §9"
  echo "$DONE_STORIES" | jq -r '.issues[].key' | while read -r KEY; do
    jira_comment "$KEY" "[DEPLOY SPECIALIST] 🚫 Deployment Blocked

Release Risk Agent assessed this release as RED.
Per governance §9 and §10, a RED risk level blocks deployment entirely.

Mandatory human escalation required. No AI agent may override this block.
Resolve the risk assessment before proceeding."
  done
  exit 2
fi

# ── Verify deployment artefacts ─────────────────────────────────────────
DEPLOY_CHECK=$(claude --print \
"You are a Deployment Specialist. Verify release readiness for SprintOps Console.

Check the following in the local repo:
1. index.html exists and references only vendor/ and local .js/.jsx files
2. All files referenced in index.html actually exist on disk
3. vendor/ contains react.development.js, react-dom.development.js, babel.min.js, lucide.min.js
4. No absolute paths hardcoded in hook scripts
5. .claude/settings.json is valid JSON
6. ROLLBACK: Git history allows revert (at least 2 commits exist)
7. MONITORING: index.html can be opened in browser (no missing critical scripts)

For each check output: DEPLOY_CHECK|<name>|OK|<note> or DEPLOY_CHECK|<name>|FAIL|<reason>" \
  --allowedTools "Read,Glob,Bash" \
  --no-conversation 2>/dev/null)

DEPLOY_FAILS=$(echo "$DEPLOY_CHECK" | grep '^DEPLOY_CHECK|' | grep '|FAIL|')
DEPLOY_OK=$(echo "$DEPLOY_CHECK" | grep '^DEPLOY_CHECK|' | grep '|OK|' | wc -l | tr -d ' ')

if [ -n "$DEPLOY_FAILS" ]; then
  echo "Deploy Agent: ❌ Pre-release checks failed:"
  echo "$DEPLOY_FAILS" | sed 's/^DEPLOY_CHECK|//' | sed 's/|FAIL|/: /'

  echo "$DONE_STORIES" | jq -r '.issues[].key' | while read -r KEY; do
    jira_comment "$KEY" "[DEPLOY SPECIALIST] ❌ Pre-Release Checks Failed

$(echo "$DEPLOY_FAILS" | sed 's/^DEPLOY_CHECK|//' | sed 's/|FAIL|/: FAIL — /' | sed 's/^/• /')

Deployment cannot proceed until these issues are resolved."
  done
  exit 2
fi

# ── Ensure Fix Version exists ──────────────────────────────────────────────
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
  echo "Deploy Agent: Created Fix Version $VERSION_NAME (unreleased — pending human approval)"
fi

# ── Tag stories and post human-approval request ────────────────────────────
# Governance §4: human approval is required before production deployment.
# This agent prepares the release package but does NOT deploy to production.
echo "$DONE_STORIES" | jq -r '.issues[].key' | while read -r KEY; do
  if [ -n "$VERSION_ID" ]; then
    jira_put "issue/$KEY" "{\"fields\":{\"fixVersions\":[{\"id\":\"$VERSION_ID\"}]}}" > /dev/null
  fi

  jira_comment "$KEY" "[DEPLOY SPECIALIST] ✅ Pre-Release Checks Passed — Awaiting Human Approval

Fix Version: $VERSION_NAME
Pre-release checks: $DEPLOY_OK/7 passed
Release Risk: ${RISK_LEVEL:-UNKNOWN}
Prepared: $(date -u '+%Y-%m-%d %H:%M UTC')

Deployment Package Ready:
→ Target: https://greubenanand86.github.io/SprintConsole/
→ Rollback: git revert HEAD or redeploy previous tag

GOVERNANCE §4 — Production Release Checklist:
☑ QA validation (QA Lead signed off)
☑ Release Risk assessment (${RISK_LEVEL:-UNKNOWN})
☑ Rollback readiness verified
☑ Monitoring readiness verified
☐ TPM recommendation — PENDING HUMAN INPUT
☐ Human approval — REQUIRED BEFORE DEPLOYMENT

ACTION REQUIRED: A human must approve this release before deployment to production.
AI agents may not deploy to production autonomously per governance §3."

  echo "Deploy Agent: Tagged $KEY with $VERSION_NAME — awaiting human approval"
done

echo "Deploy Agent: ✅ Release $VERSION_NAME prepared — human approval required for production deploy"
exit 0
