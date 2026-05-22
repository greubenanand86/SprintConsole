#!/usr/bin/env bash
# Deployment Specialist Agent
# Triggered when QA signs off (stories move to Done)
# Verifies deployment readiness, triggers GitHub Pages, updates Jira Fix Version

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/jira.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# ── Check for newly-done stories ───────────────────────────────────────────
DONE_STORIES=$(jira_get "search?jql=project=$JIRA_PROJECT+AND+status=Done+AND+updated>=-1h&maxResults=20&fields=summary,fixVersions")
COUNT=$(echo "$DONE_STORIES" | jq '.issues | length')

[ "$COUNT" -eq 0 ] && exit 0

echo "Deploy Agent: $COUNT stories completed — checking deployment readiness"

# ── Verify deployment artefacts ─────────────────────────────────────────
DEPLOY_CHECK=$(claude --print \
"You are a Deployment Specialist. Verify GitHub Pages deployment readiness for SprintOps Console.

Check the following in /home/claude/repo (or the local repo root):
1. index.html exists and references only files in vendor/ and local .js/.jsx files
2. All files referenced in index.html actually exist on disk
3. vendor/ contains react.development.js, react-dom.development.js, babel.min.js, lucide.min.js
4. No absolute paths like /home/claude/ hardcoded in hook scripts (use relative paths for portability)
5. .claude/settings.json is valid JSON

For each check output: DEPLOY_CHECK|<name>|OK|<note> or DEPLOY_CHECK|<name>|FAIL|<reason>" \
  --allowedTools "Read,Glob,Bash" \
  --no-conversation 2>/dev/null)

DEPLOY_FAILS=$(echo "$DEPLOY_CHECK" | grep '^DEPLOY_CHECK|' | grep '|FAIL|')
DEPLOY_OK=$(echo "$DEPLOY_CHECK" | grep '^DEPLOY_CHECK|' | grep '|OK|' | wc -l | tr -d ' ')

if [ -n "$DEPLOY_FAILS" ]; then
  echo "Deploy Agent: ❌ Deployment blocked — issues found:"
  echo "$DEPLOY_FAILS" | sed 's/^DEPLOY_CHECK|//' | sed 's/|FAIL|/: /'

  # Comment on all done stories about the blocker
  echo "$DONE_STORIES" | jq -r '.issues[].key' | while read -r KEY; do
    jira_comment "$KEY" "[DEPLOY SPECIALIST] ⚠️ Deployment blocked:
$(echo "$DEPLOY_FAILS" | sed 's/^DEPLOY_CHECK|//' | sed 's/|FAIL|/: FAIL — /' | sed 's/^/• /')
Please resolve before next deploy."
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
    '{"name":$name,"project":$proj,"releaseDate":$date,"released":true}')
  VERSION_RESULT=$(jira_post "version" "$VERSION_PAYLOAD")
  VERSION_ID=$(echo "$VERSION_RESULT" | jq -r '.id // ""')
  echo "Deploy Agent: Created Fix Version $VERSION_NAME"
fi

# ── Tag all done stories with Fix Version and comment ──────────────────────
echo "$DONE_STORIES" | jq -r '.issues[].key' | while read -r KEY; do
  if [ -n "$VERSION_ID" ]; then
    jira_put "issue/$KEY" "{\"fields\":{\"fixVersions\":[{\"id\":\"$VERSION_ID\"}]}}" > /dev/null
  fi
  jira_comment "$KEY" "[DEPLOY SPECIALIST] ✅ Deployed to GitHub Pages
Fix Version: $VERSION_NAME
URL: https://greubenanand86.github.io/SprintConsole/
Checks passed: $DEPLOY_OK/5
Deployed: $(date -u '+%Y-%m-%d %H:%M UTC')"
  echo "Deploy Agent: Tagged $KEY with $VERSION_NAME"
done

echo "Deploy Agent: ✅ Deployment verified — $COUNT stories shipped in $VERSION_NAME"
exit 0
