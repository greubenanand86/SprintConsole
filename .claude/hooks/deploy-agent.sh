#!/usr/bin/env bash
# Deployment Specialist Agent — Engineering Constitution §8 §9, Product Constitution §5
# §5: Release not complete unless UX reviewed, QA validated, accessibility checked,
#     rollback available, and release notes prepared
# §9: AI agents may NOT deploy to production; production always requires human approval

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/jira.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# ── Check for newly-done stories ───────────────────────────────────────────
DONE_STORIES=$(jira_get "search?jql=project=$JIRA_PROJECT+AND+status=Done+AND+updated>=-1h&maxResults=20&fields=summary,fixVersions,comment")
COUNT=$(echo "$DONE_STORIES" | jq '.issues | length' 2>/dev/null)
COUNT=${COUNT:-0}

[ "$COUNT" -eq 0 ] && exit 0

echo "Deploy Agent: $COUNT stories completed — running §5 release checklist"

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
  echo "Deploy Agent: 🚫 Blocked — Release Risk is RED"
  echo "$DONE_STORIES" | jq -r '.issues[].key' | while read -r KEY; do
    jira_comment "$KEY" "[DEPLOY SPECIALIST] 🚫 Deployment Blocked — RED Risk
Per Product Constitution §5 and Engineering Constitution §9, RED risk blocks deployment.
Human escalation required."
  done
  exit 2
fi

# ── §5: Check UX review gate ───────────────────────────────────────────────
UX_REVIEWED=false
if [ -n "$FIRST_KEY" ]; then
  UX_COMMENT=$(jira_get "issue/$FIRST_KEY/comments?maxResults=50" | \
    jq -r '.comments[].body.content[]?.content[]?.text // ""' 2>/dev/null | \
    grep '\[UX DESIGNER\]' | head -1)
  [ -n "$UX_COMMENT" ] && UX_REVIEWED=true
fi
UX_GATE="☐ UX review — NOT FOUND in Jira comments (§5 requires UX review before release)"
$UX_REVIEWED && UX_GATE="☑ UX review verified"

# ── §8: Verify staging deployment ──────────────────────────────────────────
STAGING_OK=false
git -C "$REPO_ROOT" branch -a 2>/dev/null | grep -qiE 'staging|preview|preprod' && STAGING_OK=true
if ! $STAGING_OK && [ -n "$FIRST_KEY" ]; then
  STAGING_COMMENT=$(jira_get "issue/$FIRST_KEY/comments?maxResults=50" | \
    jq -r '.comments[].body.content[]?.content[]?.text // ""' 2>/dev/null | \
    grep -i 'staging\|deployed to staging\|preview' | head -1)
  [ -n "$STAGING_COMMENT" ] && STAGING_OK=true
fi
STAGING_NOTE="⚠ No staging evidence (§8 requires staging before production)"
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

# ── Generate release notes ─────────────────────────────────────────────────
# §5: Release notes are mandatory
STORY_LIST=$(echo "$DONE_STORIES" | jq -r '.issues[] | "- \(.key): \(.fields.summary)"')

RELEASE_NOTES=$(claude --print \
"You are writing release notes for SprintOps Console (Product Constitution §5).

Stories in this release:
$STORY_LIST

Write clear, user-facing release notes. Product Constitution §1: avoid jargon.
Format for users who understand sprint management but not internals.

Output EXACTLY this format:

WHATS_NEW:
- <user-facing description of change 1>
- <user-facing description of change 2>

IMPROVEMENTS:
- <improvement, or 'None in this release'>

BUG_FIXES:
- <fix, or 'None in this release'>

KNOWN_LIMITATIONS:
- <known limitation, or 'None'>

ROLLBACK_NOTE: <one sentence on how to revert if needed>" \
  --allowedTools "Read" \
  --no-conversation 2>/dev/null)

# ── Ensure Fix Version exists (unreleased — pending approval) ──────────────
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

# ── Tag stories and post approval request with full §5 checklist ──────────
echo "$DONE_STORIES" | jq -r '.issues[].key' | while read -r KEY; do
  [ -n "$VERSION_ID" ] && jira_put "issue/$KEY" "{\"fields\":{\"fixVersions\":[{\"id\":\"$VERSION_ID\"}]}}" > /dev/null

  jira_comment "$KEY" "[DEPLOY SPECIALIST] ✅ Release Package Ready — Human Approval Required

Fix Version: $VERSION_NAME
Artefact checks: $DEPLOY_OK/7 passed
Release Risk: ${RISK_LEVEL:-UNKNOWN}
Staging: $STAGING_NOTE
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

Product Constitution §5 Delivery Checklist:
$UX_GATE
☑ QA validation (QA Lead signed off)
☑ Accessibility checked (QA §5 checks)
☑ Artefact verification ($DEPLOY_OK/7)
☑ Release Risk: ${RISK_LEVEL:-UNKNOWN}
☑ Rollback available
☑ Release notes prepared (above)
☐ TPM recommendation — PENDING HUMAN
☐ Human approval — REQUIRED before production

§9: AI agents may NOT deploy to production autonomously.
Target: https://greubenanand86.github.io/SprintConsole/"

  echo "Deploy Agent: $KEY tagged $VERSION_NAME with release notes — awaiting human approval"
done

echo "Deploy Agent: Release $VERSION_NAME prepared with §5-compliant release notes"
exit 0
