#!/bin/bash
set -euo pipefail

: "${LB_ID:?LB_ID is required}"
: "${BACKEND_SET_NAME:?BACKEND_SET_NAME is required}"
: "${IP_ADDRESS:?IP_ADDRESS is required}"
: "${PORT:?PORT is required}"

# Register the new backend
oci lb backend create \
  --load-balancer-id "$LB_ID" \
  --backend-set-name "$BACKEND_SET_NAME" \
  --ip-address "$IP_ADDRESS" \
  --port "$PORT" \
  --wait-for-state SUCCEEDED

echo "Registered new backend ${IP_ADDRESS}:${PORT}"

# Wait until the new backend health status is OK before touching old backends
BACKEND_NAME="${IP_ADDRESS}:${PORT}"
MAX_WAIT=120
INTERVAL=5
ELAPSED=0

echo "Waiting for backend ${BACKEND_NAME} to become healthy..."
while true; do
  STATUS=$(oci lb backend-health get \
    --load-balancer-id "$LB_ID" \
    --backend-set-name "$BACKEND_SET_NAME" \
    --backend-name "$BACKEND_NAME" \
    --output json 2>/dev/null \
    | jq -r '.data.status // "UNKNOWN"')

  echo "  Health status: $STATUS (${ELAPSED}s elapsed)"

  if [ "$STATUS" = "OK" ]; then
    echo "Backend ${BACKEND_NAME} is healthy — proceeding to remove old backends"
    break
  fi

  if [ "$ELAPSED" -ge "$MAX_WAIT" ]; then
    echo "ERROR: backend ${BACKEND_NAME} did not become healthy within ${MAX_WAIT}s (last status: $STATUS)" >&2
    exit 1
  fi

  sleep $INTERVAL
  ELAPSED=$((ELAPSED + INTERVAL))
done

# Drain and delete any old backends (different IP) still in the set
OLD_BACKENDS=$(oci lb backend list \
  --load-balancer-id "$LB_ID" \
  --backend-set-name "$BACKEND_SET_NAME" \
  --output json \
  | jq -r --arg ip "$IP_ADDRESS" '.data[] | select(."ip-address" != $ip) | "\(."ip-address"):\(.port)"')

for BACKEND_NAME in $OLD_BACKENDS; do
  echo "Draining old backend $BACKEND_NAME..."
  oci lb backend update \
    --load-balancer-id "$LB_ID" \
    --backend-set-name "$BACKEND_SET_NAME" \
    --backend-name "$BACKEND_NAME" \
    --drain true \
    --offline true \
    --backup false \
    --weight 1 \
    --wait-for-state SUCCEEDED

  echo "Deleting old backend $BACKEND_NAME..."
  oci lb backend delete \
    --load-balancer-id "$LB_ID" \
    --backend-set-name "$BACKEND_SET_NAME" \
    --backend-name "$BACKEND_NAME" \
    --force \
    --wait-for-state SUCCEEDED

  echo "Removed old backend $BACKEND_NAME"
done
