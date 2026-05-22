#!/usr/bin/env bash
#
# Upserts a single rule (by name) into an existing OCI Load Balancer routing
# policy. Safe to run concurrently from multiple Terraform applies — uses
# ETag-based optimistic concurrency with exponential backoff retries.
#
# Required env vars: LB_ID, POLICY_NAME, RULE_NAME, RULE_CONDITION, BACKEND_SET_NAME

set -euo pipefail

: "${LB_ID:?LB_ID is required}"
: "${POLICY_NAME:?POLICY_NAME is required}"
: "${RULE_NAME:?RULE_NAME is required}"
: "${RULE_CONDITION:?RULE_CONDITION is required}"
: "${BACKEND_SET_NAME:?BACKEND_SET_NAME is required}"

command -v oci >/dev/null || { echo "ERROR: oci CLI not found in PATH" >&2; exit 1; }
command -v jq  >/dev/null || { echo "ERROR: jq not found in PATH"     >&2; exit 1; }

MAX_RETRIES=10
ATTEMPT=0

while [ $ATTEMPT -lt $MAX_RETRIES ]; do
  ATTEMPT=$((ATTEMPT + 1))

  RESPONSE=$(oci lb routing-policy get \
    --load-balancer-id "$LB_ID" \
    --routing-policy-name "$POLICY_NAME" \
    --output json 2>/dev/null) || {
      echo "ERROR: routing policy '$POLICY_NAME' not found on LB '$LB_ID'" >&2
      exit 1
    }

  ETAG=$(echo "$RESPONSE" | jq -r '.etag')
  CURRENT_RULES=$(echo "$RESPONSE" | jq '.data.rules // []')

  NEW_RULE=$(jq -n \
    --arg name "$RULE_NAME" \
    --arg cond "$RULE_CONDITION" \
    --arg bs   "$BACKEND_SET_NAME" \
    '{
      name: $name,
      condition: $cond,
      actions: [{
        name: "FORWARD_TO_BACKENDSET",
        "backend-set-name": $bs
      }]
    }')

  NEW_RULES=$(echo "$CURRENT_RULES" | jq \
    --arg name "$RULE_NAME" \
    --argjson newrule "$NEW_RULE" \
    '[.[] | select(.name != $name)] + [$newrule]')

  if oci lb routing-policy update \
       --load-balancer-id "$LB_ID" \
       --routing-policy-name "$POLICY_NAME" \
       --rules "$NEW_RULES" \
       --if-match "$ETAG" \
       --force \
       --wait-for-state SUCCEEDED \
       --wait-for-state FAILED \
       --output json >/dev/null 2>&1; then
    echo "Rule '$RULE_NAME' upserted into '$POLICY_NAME' (attempt $ATTEMPT)"
    exit 0
  fi

  BACKOFF=$((2 ** ATTEMPT + RANDOM % 3))
  echo "Update failed (likely ETag conflict), retrying in ${BACKOFF}s (attempt $ATTEMPT/$MAX_RETRIES)" >&2
  sleep $BACKOFF
done

echo "ERROR: failed to upsert rule '$RULE_NAME' after $MAX_RETRIES attempts" >&2
exit 1
