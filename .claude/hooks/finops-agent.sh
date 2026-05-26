#!/usr/bin/env bash
# FinOps & Cost Optimization Agent — Per Agent Role Specifications v1.0 §18
# Mission: Monitor and reduce unnecessary infrastructure, API, and AI usage costs
# Authority: Recommend cost optimization; cannot block security/stability work; cannot change infrastructure
# Usage: finops-agent.sh [JIRA-KEY]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[ -f "$SCRIPT_DIR/jira.sh" ] && source "$SCRIPT_DIR/jira.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

KEY="${1:-}"

if [ -z "$KEY" ]; then
  # Auto-scan: find stories that touch infra, APIs, or AI usage
  STORIES=$(jira_get "search?jql=project=$JIRA_PROJECT+AND+labels+in+(infra,api,ai,cloud,integration)+AND+status+in+(%22Refined%22,%22Ready+for+Development%22,%22In+Development%22)&maxResults=10&fields=summary,status" 2>/dev/null || echo '{"issues":[]}')
  COUNT=$(echo "$STORIES" | jq '.issues | length' 2>/dev/null)
  [ "$COUNT" -eq 0 ] && exit 0

  echo "[FINOPS] Auto-scan: $COUNT infra/API/AI stories for cost review"
  echo "$STORIES" | jq -r '.issues[].key' | while read -r K; do
    "$0" "$K"
  done
  exit 0
fi

# Single-story cost review
ISSUE=$(jira_get "issue/$KEY?fields=summary,status,description" 2>/dev/null || echo '{}')
TITLE=$(echo "$ISSUE" | jq -r '.fields.summary // "Unknown"')
STATE=$(echo "$ISSUE" | jq -r '.fields.status.name // "In Progress"')

# Detect cost categories
IS_AI=$(echo "$TITLE" | grep -iE 'ai|llm|claude|gpt|openai|model|inference|embedding|vector' && echo "yes" || echo "no")
IS_CLOUD=$(echo "$TITLE" | grep -iE 'cloud|aws|azure|gcp|infra|database|storage|bucket|lambda|function|server' && echo "yes" || echo "no")
IS_THIRD_PARTY=$(echo "$TITLE" | grep -iE 'integration|webhook|api.*call|external.*service|sdk|vendor' && echo "yes" || echo "no")
IS_SEARCH=$(echo "$TITLE" | grep -iE 'search|index|query|analytics|metrics|log' && echo "yes" || echo "no")

cat << EOF
[FINOPS] $KEY — Cost Optimization Review

## 1. Cost Scope
- Story: $KEY — $TITLE
- Status: $STATE
- Cost Categories: $([ "$IS_AI" = "yes" ] && echo "AI/LLM Inference" || echo "—")\
$([ "$IS_CLOUD" = "yes" ] && echo " Cloud Infrastructure" || echo "")\
$([ "$IS_THIRD_PARTY" = "yes" ] && echo " Third-Party API" || echo "")\
$([ "$IS_SEARCH" = "yes" ] && echo " Search/Analytics" || echo "")
- Per METRICS_DASHBOARD_FRAMEWORK v1.0 and ARCHITECTURE_BLUEPRINT v1.0

## 2. Estimated Cost Impact
$(
  if [ "$IS_AI" = "yes" ]; then
    echo "AI Token/Call Costs:"
    echo "  - Model: Identify which Claude/OpenAI model is being called"
    echo "  - Frequency: Calls per user action vs background batch"
    echo "  - Token count: Input + output tokens per call (estimate)"
    echo "  - Caching: Is prompt caching enabled? (reduces cost by up to 90%)"
    echo "  - Batching: Are requests batched where possible?"
    echo ""
    echo "  Estimate required before production:"
    echo "    Cost = (calls/day × avg_tokens × token_price)"
    echo "    Set spending alerts at 110%, 150% of budget baseline"
  fi

  if [ "$IS_CLOUD" = "yes" ]; then
    echo "Cloud Infrastructure Costs:"
    echo "  - Compute: New services, functions, or containers?"
    echo "  - Storage: New buckets, databases, volumes?"
    echo "  - Network: Cross-region traffic, data egress?"
    echo "  - Scaling: Auto-scaling triggers configured correctly?"
    echo ""
    echo "  Infrastructure change → [ARCHITECT] review required"
    echo "  Cost estimate → attach to Architecture handoff packet"
  fi

  if [ "$IS_THIRD_PARTY" = "yes" ]; then
    echo "Third-Party API Costs:"
    echo "  - Pricing tier: Free / Pay-per-call / Monthly subscription?"
    echo "  - Call volume: Calls/day estimate at steady state?"
    echo "  - Rate limits: Will we hit limits at scale?"
    echo "  - Overage: What happens when rate limit exceeded?"
  fi

  [ "$IS_AI" = "no" ] && [ "$IS_CLOUD" = "no" ] && [ "$IS_THIRD_PARTY" = "no" ] && \
    echo "No significant cost impact detected for this story type."
)

## 3. Risk of Cost Growth
$(
  if [ "$IS_AI" = "yes" ]; then
    echo "🔴 HIGH cost risk: AI inference is the highest variable cost"
    echo "  Risk factors:"
    echo "  - Uncontrolled call frequency (no rate limiting)"
    echo "  - Large context windows without caching"
    echo "  - Recursive or looping AI calls"
    echo "  - Over-provisioned model (Opus for tasks Haiku can handle)"
  elif [ "$IS_CLOUD" = "yes" ]; then
    echo "🟡 MEDIUM cost risk: Infrastructure changes can have unexpected growth"
    echo "  Risk factors:"
    echo "  - Auto-scaling without spending cap"
    echo "  - Unindexed queries causing full table scans"
    echo "  - Log retention without lifecycle policy"
  elif [ "$IS_THIRD_PARTY" = "yes" ]; then
    echo "🟡 MEDIUM cost risk: Third-party API costs depend on usage volume"
    echo "  Risk factors:"
    echo "  - No per-user rate limiting"
    echo "  - Redundant API calls (no caching)"
    echo "  - Vendor price changes"
  else
    echo "✅ LOW cost risk: Standard feature, no significant infrastructure changes"
  fi
)

## 4. Optimization Options
$(
  if [ "$IS_AI" = "yes" ]; then
    echo "AI Cost Optimizations:"
    echo "  1. Right-size the model — use Haiku for simple tasks, Sonnet for complex, Opus for highest-quality only"
    echo "  2. Prompt caching — cache repeated system prompts (up to 90% cost reduction)"
    echo "  3. Batch processing — group non-realtime requests into Batch API (50% discount)"
    echo "  4. Output token control — set max_tokens to expected output length"
    echo "  5. Caching at application layer — cache identical requests for same input"
    echo "  6. Streaming — use streaming for long outputs to improve user experience"
  fi

  if [ "$IS_CLOUD" = "yes" ]; then
    echo "Cloud Cost Optimizations:"
    echo "  1. Right-size compute — start small, scale up based on metrics"
    echo "  2. Spot/preemptible instances for non-critical batch workloads"
    echo "  3. S3/blob lifecycle policies — archive or delete stale data"
    echo "  4. Database connection pooling — avoid connection-per-request pattern"
    echo "  5. CDN caching — cache static assets at edge"
  fi

  if [ "$IS_THIRD_PARTY" = "yes" ]; then
    echo "Third-Party API Optimizations:"
    echo "  1. Response caching — cache API responses for TTL-appropriate data"
    echo "  2. Request deduplication — batch similar requests"
    echo "  3. Tier review — negotiate pricing at scale if high volume expected"
  fi
)

## 5. Tradeoffs
$(
  if [ "$IS_AI" = "yes" ]; then
    echo "Cost vs Quality:"
    echo "  - Haiku vs Opus: Haiku is ~10x cheaper but lower quality"
    echo "    → Use Haiku for: classification, simple extraction, routine tasks"
    echo "    → Use Sonnet for: complex reasoning, multi-step analysis"
    echo "    → Use Opus for: highest-stakes decisions only"
    echo ""
    echo "  - Caching reduces cost but delays fresh responses"
    echo "    → Acceptable for: stable system prompts, read-only data"
    echo "    → Not acceptable for: real-time data, user-specific context"
  fi

  if [ "$IS_CLOUD" = "yes" ]; then
    echo "Cost vs Performance:"
    echo "  - Smaller instances = lower cost, higher latency"
    echo "  - Auto-scaling = flexible cost, cold start penalty"
    echo "  - Reserved instances = lower long-term cost, commitment risk"
  fi

  echo ""
  echo "GOVERNANCE CONSTRAINT: Cost optimization cannot block:"
  echo "  - Security fixes (Security Baseline v1.0 §1)"
  echo "  - Stability improvements (Engineering Constitution §2)"
  echo "  - Critical production incidents (Incident Playbook §4)"
)

## 6. Recommendation
$(
  if [ "$IS_AI" = "yes" ]; then
    echo "⚠️ ACTION REQUIRED BEFORE PRODUCTION:"
    echo "  1. Document model choice and rationale (Haiku / Sonnet / Opus)"
    echo "  2. Enable prompt caching for system prompts"
    echo "  3. Set max_tokens to realistic output bound"
    echo "  4. Add spending alerts (110% baseline)"
    echo "  5. Review actual cost in first week post-launch"
  elif [ "$IS_CLOUD" = "yes" ] || [ "$IS_THIRD_PARTY" = "yes" ]; then
    echo "📋 REVIEW BEFORE PRODUCTION:"
    echo "  1. Attach cost estimate to Architecture handoff packet"
    echo "  2. Confirm spending alerts configured"
    echo "  3. Confirm auto-scaling bounds set"
  else
    echo "✅ No cost action required — standard feature"
  fi
)

## 7. Escalation Needed?
$(
  if [ "$IS_AI" = "yes" ]; then
    echo "Yes — Coordinate with Architecture and TPM agents"
    echo "  - AI inference cost can exceed infra budget rapidly"
    echo "  - Escalate if monthly AI cost estimate > 10% of infra budget"
    echo "  - TPM tracks cost as a delivery risk item"
  elif [ "$IS_CLOUD" = "yes" ]; then
    echo "Possibly — Review with [ARCHITECT] if infra changes are significant"
    echo "  - Escalate to TPM if cost estimate is material to delivery budget"
  else
    echo "No — Cost impact is low or negligible"
  fi
)

---
[FinOps & Cost Optimization Agent] — Per Agent Role Specifications v1.0 §18 | METRICS_DASHBOARD_FRAMEWORK v1.0
NOTE: Cannot block security/stability work for cost reasons. Cannot change infrastructure autonomously.
EOF

jira_comment "$KEY" "[FINOPS] 💰 Cost optimization review prepared.
Impact estimates, optimization options, and tradeoffs documented.
[FinOps & Cost Optimization Agent]" 2>/dev/null || true
