#!/usr/bin/env bash
#
# Removes a single rule (by name) from an existing OCI Load Balancer routing
# policy. Safe to run concurrently — uses ETag-based optimistic concurrency
# with retries. Idempotent: no error if the rule is already gone.
#
# Required env vars: LB_ID, POLICY_NAME, RULE_NAME

set -euo pipefail

: "${LB_ID:?LB_ID is required}"
: "${POLICY_NAME:?POLICY_NAME is required}"
: "${RULE_NAME:?RULE_NAME is required}"

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
      echo "Routing policy '$POLICY_NAME' not found — treating as already removed"
      exit 0
    }

  ETAG=$(echo "$RESPONSE" | jq -r '.etag')
  CURRENT_RULES=$(echo "$RESPONSE" | jq '.data.rules // []')

  HAS_RULE=$(echo "$CURRENT_RULES" | jq --arg name "$RULE_NAME" 'any(.name == $name)')
  if [ "$HAS_RULE" = "false" ]; then
    echo "Rule '$RULE_NAME' already absent from '$POLICY_NAME' — nothing to do"
    exit 0
  fi

  NEW_RULES=$(echo "$CURRENT_RULES" | jq \
    --arg name "$RULE_NAME" \
    '[.[] | select(.name != $name)]')

  if oci lb routing-policy update \
       --load-balancer-id "$LB_ID" \
       --routing-policy-name "$POLICY_NAME" \
       --rules "$NEW_RULES" \
       --if-match "$ETAG" \
       --force \
       --wait-for-state SUCCEEDED \
       --wait-for-state FAILED \
       --output json >/dev/null 2>&1; then
    echo "Rule '$RULE_NAME' removed from '$POLICY_NAME' (attempt $ATTEMPT)"
    exit 0
  fi

  BACKOFF=$((2 ** ATTEMPT + RANDOM % 3))
  echo "Update failed (likely ETag conflict), retrying in ${BACKOFF}s (attempt $ATTEMPT/$MAX_RETRIES)" >&2
  sleep $BACKOFF
done

echo "ERROR: failed to remove rule '$RULE_NAME' after $MAX_RETRIES attempts" >&2
exit 1
