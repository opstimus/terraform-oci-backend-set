#!/bin/bash
set -euo pipefail

: "${LB_ID:?LB_ID is required}"
: "${BACKEND_SET_NAME:?BACKEND_SET_NAME is required}"
: "${IP_ADDRESS:?IP_ADDRESS is required}"
: "${PORT:?PORT is required}"

BACKEND_NAME="${IP_ADDRESS}:${PORT}"

# Check if backend still exists — it may already be cleaned up by register_backend.sh
EXISTS=$(oci lb backend list \
  --load-balancer-id "$LB_ID" \
  --backend-set-name "$BACKEND_SET_NAME" \
  --output json \
  | jq -r --arg name "$BACKEND_NAME" '.data[] | select("\(."ip-address"):\(.port)" == $name) | .name' \
  2>/dev/null || true)

if [ -z "$EXISTS" ]; then
  echo "Backend $BACKEND_NAME already absent — nothing to do"
  exit 0
fi

# Drain and take offline first — required by OCI before deletion is allowed
oci lb backend update \
  --load-balancer-id "$LB_ID" \
  --backend-set-name "$BACKEND_SET_NAME" \
  --backend-name "$BACKEND_NAME" \
  --drain true \
  --offline true \
  --backup false \
  --weight 1 \
  --wait-for-state SUCCEEDED

# Delete the backend
oci lb backend delete \
  --load-balancer-id "$LB_ID" \
  --backend-set-name "$BACKEND_SET_NAME" \
  --backend-name "$BACKEND_NAME" \
  --force \
  --wait-for-state SUCCEEDED

echo "Deregistered backend $BACKEND_NAME"
