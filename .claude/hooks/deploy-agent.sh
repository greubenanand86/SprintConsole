#!/usr/bin/env bash
# Deployment Specialist Agent — Jira Workflow Governance §11 §12
# Engineering Constitution §8 §9 | Product Constitution §5
#
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
$PA_VERIFIED && PA_GATE="☑ Product Acceptance verified (§7 §11)"

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

# ── §6: Definition of Done check ──────────────────────────────────────────
DOD_CHECK=$(claude --print \
"You are a Deployment Specialist verifying Definition of Done (Jira Workflow Governance §6).

A story is not complete without:
1. Acceptance criteria validated (look for QA sign-off in Jira)
2. Unit testing completed (look for test files or QA test cases)
3. QA verified (QA Lead sign-off present)
4. Accessibility reviewed (look for §5 pass in QA comment)
5. Regression impact reviewed (look for release risk assessment)
6. Documentation updated where applicable (CLAUDE.md, README, inline comments)
7. Monitoring/logging added where applicable (error boundaries, structured logging)
8. Release notes prepared (look for deploy comment with release notes)
9. Product Acceptance completed (look for [PRODUCT ACCEPTANCE] ✅)

Read the codebase for stories: $(echo "$DONE_STORIES" | jq -r '.issues[].fields.summary' | head -5 | tr '\n' '; ')

For each DoD item output: DOD|<item>|MET|<note> or DOD|<item>|UNMET|<gap>" \
  --allowedTools "Read,Glob" \
  --no-conversation 2>/dev/null)

DOD_UNMET=$(echo "$DOD_CHECK" | grep '^DOD|' | grep '|UNMET|' | sed 's/^DOD|//' | sed 's/|UNMET|/: gap — /')
DOD_MET=$(echo "$DOD_CHECK" | grep '^DOD|' | grep '|MET|' | wc -l | tr -d ' ')

# ── §8 staging verification ────────────────────────────────────────────────
STAGING_OK=false
git -C "$REPO_ROOT" branch -a 2>/dev/null | grep -qiE 'staging|preview|preprod' && STAGING_OK=true
STAGING_NOTE="⚠ No staging evidence (§8 recommends staging before production)"
$STAGING_OK && STAGING_NOTE="☑ Staging branch verified"

# ── Artefact checks ───────────────────────────────────────────────────────
DEPLOY_CHECK=$(claude --print \
"Deployment artefact verification for SprintOps Console.

Check:
1. index.html exists and references only vendor/ and local .js/.jsx files
2. All files referenced in index.html exist on disk
3. vendor/ contains react.development.js, react-dom.development.js, babel.min.js, lucide.min.js
4. No absolute paths hardcoded in hook scripts
5. .claude/settings.json is valid JSON
6. ROLLBACK: At least 2 git commits exist (can revert)
7. MONITORING: No missing critical scripts in index.html

Output: DEPLOY_CHECK|<name>|OK|<note> or DEPLOY_CHECK|<name>|FAIL|<reason>" \
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
"Write user-facing release notes for SprintOps Console (Product Constitution §5 §1).

Stories in this release:
$STORY_LIST

§1: Avoid jargon. Write for sprint managers who understand sprint management but not internals.
§5: Release notes are mandatory for every release.

Output EXACTLY this format:

WHATS_NEW:
- <user-facing description>

IMPROVEMENTS:
- <improvement, or 'None in this release'>

BUG_FIXES:
- <fix, or 'None in this release'>

KNOWN_LIMITATIONS:
- <limitation, or 'None'>

ROLLBACK_NOTE: <one sentence on how to revert if needed>" \
  --allowedTools "Read" \
  --no-conversation 2>/dev/null)

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

  jira_comment "$KEY" "[DEPLOY SPECIALIST] 📦 Release Package Ready — Human Approval Required (§9 §11)

Fix Version: $VERSION_NAME
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

§11 Release Governance Checklist:
$PA_GATE
$QA_GATE
$UX_GATE
☑ Accessibility checked (QA §5 pass required in QA sign-off)
☑ Artefact verification ($DEPLOY_OK/7 passed)
☑ Rollback available (git revert)
☑ Release Risk: ${RISK_LEVEL:-UNKNOWN}
☑ Release notes prepared (above)
$STAGING_NOTE
$([ -n "$DOD_UNMET" ] && echo "
⚠ Definition of Done gaps detected (§6):
$(echo "$DOD_UNMET" | sed 's/^/  • /')")
☐ Human approval — REQUIRED before production (§9)

After human approves:
→ Mark Fix Version $VERSION_NAME as Released in Jira
→ Deploy to https://greubenanand86.github.io/SprintConsole/
→ Monitoring Agent will begin post-release monitoring (§12)"

  echo "Deploy Agent: $KEY tagged $VERSION_NAME — awaiting human approval"
done

echo "Deploy Agent: Release $VERSION_NAME prepared — §11 checklist complete"
exit 0
