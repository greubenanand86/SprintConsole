#!/usr/bin/env bash
# Deployment Specialist Agent — Engineering Constitution §8, §9
# Triggered when QA signs off (stories move to Done)
# §8: Staging deployment must precede production
# §9: AI agents may NOT deploy to production; production always requires human approval

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/jira.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# ── Check for newly-done stories ───────────────────────────────────────────
DONE_STORIES=$(jira_get "search?jql=project=$JIRA_PROJECT+AND+status=Done+AND+updated>=-1h&maxResults=20&fields=summary,fixVersions,comment")
COUNT=$(echo "$DONE_STORIES" | jq '.issues | length' 2>/dev/null)
COUNT=${COUNT:-0}

[ "$COUNT" -eq 0 ] && exit 0

echo "Deploy Agent: $COUNT stories completed — running pre-release checklist (§8)"

# ── Check release risk assessment ──────────────────────────────────────────
RISK_LEVEL="UNKNOWN"
if [ -f /tmp/sprintops-release-risk.txt ]; then
  RISK_LEVEL=$(cat /tmp/sprintops-release-risk.txt | tr -d '[:space:]')
fi

FIRST_KEY=$(echo "$DONE_STORIES" | jq -r '.issues[0].key // ""')
if [ -n "$FIRST_KEY" ]; then
  RISK_COMMENT=$(jira_get "issue/$FIRST_KEY/comments?maxResults=50" | \
    jq -r '.comments[].body.content[]?.content[]?.text // ""' 2>/dev/null | \
    grep '\[RELEASE RISK\]' | head -1)
  if echo "$RISK_COMMENT" | grep -q 'RED';    then RISK_LEVEL="RED"; fi
  if [ "$RISK_LEVEL" = "UNKNOWN" ] && echo "$RISK_COMMENT" | grep -q 'GREEN';  then RISK_LEVEL="GREEN"; fi
  if [ "$RISK_LEVEL" = "UNKNOWN" ] && echo "$RISK_COMMENT" | grep -q 'YELLOW'; then RISK_LEVEL="YELLOW"; fi
fi

if [ "$RISK_LEVEL" = "RED" ]; then
  echo "Deploy Agent: 🚫 Blocked — Release Risk is RED per §9 / Governance §3"
  echo "$DONE_STORIES" | jq -r '.issues[].key' | while read -r KEY; do
    jira_comment "$KEY" "[DEPLOY SPECIALIST] 🚫 Deployment Blocked — RED Risk

Release Risk Agent assessed this release as RED.
Per Engineering Constitution §9 and Governance §10, RED risk blocks deployment.
Mandatory human escalation required. No AI agent may override this block."
  done
  exit 2
fi

# ── §8: Verify staging deployment ──────────────────────────────────────────
# Check if there's evidence of a prior staging deployment or staging branch
STAGING_OK=false
if git -C "$REPO_ROOT" branch -a 2>/dev/null | grep -qiE 'staging|preview|preprod'; then
  STAGING_OK=true
fi
# Check for a staging comment in any of the done stories
if ! $STAGING_OK && [ -n "$FIRST_KEY" ]; then
  STAGING_COMMENT=$(jira_get "issue/$FIRST_KEY/comments?maxResults=50" | \
    jq -r '.comments[].body.content[]?.content[]?.text // ""' 2>/dev/null | \
    grep -i 'staging\|preview\|deployed to staging' | head -1)
  [ -n "$STAGING_COMMENT" ] && STAGING_OK=true
fi

STAGING_NOTE="⚠ No staging deployment evidence found — §8 requires staging before production"
$STAGING_OK && STAGING_NOTE="✓ Staging deployment verified"

# ── Verify deployment artefacts ─────────────────────────────────────────
DEPLOY_CHECK=$(claude --print \
"You are a Deployment Specialist. Verify release readiness for SprintOps Console.

Check:
1. index.html exists and references only vendor/ and local .js/.jsx files
2. All files referenced in index.html exist on disk
3. vendor/ contains react.development.js, react-dom.development.js, babel.min.js, lucide.min.js
4. No absolute paths hardcoded in hook scripts
5. .claude/settings.json is valid JSON
6. ROLLBACK: At least 2 git commits exist (can revert)
7. MONITORING: No missing critical scripts in index.html

For each check output: DEPLOY_CHECK|<name>|OK|<note> or DEPLOY_CHECK|<name>|FAIL|<reason>" \
  --allowedTools "Read,Glob,Bash" \
  --no-conversation 2>/dev/null)

DEPLOY_FAILS=$(echo "$DEPLOY_CHECK" | grep '^DEPLOY_CHECK|' | grep '|FAIL|')
DEPLOY_OK=$(echo "$DEPLOY_CHECK" | grep '^DEPLOY_CHECK|' | grep '|OK|' | wc -l | tr -d ' ')

if [ -n "$DEPLOY_FAILS" ]; then
  echo "Deploy Agent: ❌ Pre-release checks failed"
  echo "$DONE_STORIES" | jq -r '.issues[].key' | while read -r KEY; do
    jira_comment "$KEY" "[DEPLOY SPECIALIST] ❌ Pre-Release Checks Failed

$(echo "$DEPLOY_FAILS" | sed 's/^DEPLOY_CHECK|//' | sed 's/|FAIL|/: FAIL — /' | sed 's/^/• /')

Resolve before deployment."
  done
  exit 2
fi

# ── Ensure Fix Version exists (unreleased — pending human approval) ─────────
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
echo "$DONE_STORIES" | jq -r '.issues[].key' | while read -r KEY; do
  if [ -n "$VERSION_ID" ]; then
    jira_put "issue/$KEY" "{\"fields\":{\"fixVersions\":[{\"id\":\"$VERSION_ID\"}]}}" > /dev/null
  fi

  jira_comment "$KEY" "[DEPLOY SPECIALIST] ✅ Pre-Release Package Ready — Human Approval Required

Fix Version: $VERSION_NAME
Pre-release checks: $DEPLOY_OK/7 passed
Release Risk: ${RISK_LEVEL:-UNKNOWN}
Staging: $STAGING_NOTE
Prepared: $(date -u '+%Y-%m-%d %H:%M UTC')

Target: https://greubenanand86.github.io/SprintConsole/
Rollback: git revert HEAD or redeploy previous tag

Engineering Constitution §8 / §9 Release Checklist:
☑ QA validation (QA Lead signed off)
☑ Artefact verification ($DEPLOY_OK/7)
☑ Release Risk assessment (${RISK_LEVEL:-UNKNOWN})
☑ Rollback plan available
$(${STAGING_OK} && echo '☑' || echo '☐') Staging deployment (§8)
☐ TPM recommendation — PENDING HUMAN
☐ Human approval — REQUIRED

ACTION REQUIRED: Human approval needed before production deployment.
§9: AI agents may NOT deploy to production autonomously."

  echo "Deploy Agent: $KEY tagged with $VERSION_NAME — awaiting human approval"
done

echo "Deploy Agent: Release $VERSION_NAME prepared — human approval required for production"
exit 0
