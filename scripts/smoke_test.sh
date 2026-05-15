#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BASE_URL:-http://localhost:8000}"
EMAIL="${SMOKE_EMAIL:-smoke_$(date +%s)@example.com}"
PASSWORD="${SMOKE_PASSWORD:-demo12345}"
NAME="${SMOKE_NAME:-Smoke Test}"
TMP_DIR="$(mktemp -d)"
AUDIO_FILE="$TMP_DIR/dummy.mp3"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    if [[ "$cmd" == "jq" ]]; then
      echo "jq is required. Install jq and retry."
    else
      echo "Required command not found: $cmd"
    fi
    exit 1
  fi
}

require_cmd curl
require_cmd jq

echo "[0/6] Waiting for API health ($BASE_URL/health) ..."
HEALTH_OK=0
for i in {1..30}; do
  if curl -fs "$BASE_URL/health" >/dev/null; then
    HEALTH_OK=1
    break
  fi
  sleep 1
done
if [[ "$HEALTH_OK" -ne 1 ]]; then
  echo "API is not healthy after 30 seconds: $BASE_URL/health"
  exit 1
fi

printf 'ID3\x03\x00\x00\x00\x00\x00\x21TIT2\x00\x00\x00\x0F\x00\x00\x03Dummy audio\x00' > "$AUDIO_FILE"

echo "[1/6] Registering user (or continuing if already exists)..."
REGISTER_CODE=$(curl -s -o "$TMP_DIR/register.json" -w "%{http_code}" -X POST "$BASE_URL/api/v1/auth/register" \
  -H 'Content-Type: application/json' \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\",\"name\":\"$NAME\"}")
if [[ "$REGISTER_CODE" != "200" && "$REGISTER_CODE" != "201" && "$REGISTER_CODE" != "400" ]]; then
  echo "Register failed with code $REGISTER_CODE"
  cat "$TMP_DIR/register.json"
  exit 1
fi

echo "[2/6] Logging in..."
TOKEN=$(curl -s -X POST "$BASE_URL/api/v1/auth/login" \
  -H 'Content-Type: application/json' \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}" | jq -r '.access_token')
if [[ -z "$TOKEN" || "$TOKEN" == "null" ]]; then
  echo "Login failed"
  exit 1
fi

echo "[3/6] Uploading audio..."
UPLOAD_CODE=$(curl -s -o "$TMP_DIR/upload_response.txt" -w "%{http_code}" -X POST "$BASE_URL/api/v1/calls/upload" \
  -H "Authorization: Bearer $TOKEN" \
  -F "file=@$AUDIO_FILE" \
  -F "title=Smoke call" \
  -F "contact_name=Smoke Contact" \
  -F "phone_number=+15555550123")
UPLOAD_RESPONSE="$(cat "$TMP_DIR/upload_response.txt")"
echo "Upload HTTP code: $UPLOAD_CODE"
echo "Upload response body: $UPLOAD_RESPONSE"

CALL_ID=$(echo "$UPLOAD_RESPONSE" | jq -r '.id // empty' 2>/dev/null || true)
if [[ -z "$CALL_ID" || "$CALL_ID" == "null" ]]; then
  echo "Upload failed: CALL_ID is empty"
  echo "$UPLOAD_RESPONSE"
  exit 1
fi

echo "[4/6] Polling call status for $CALL_ID ..."
STATUS="uploaded"
for _ in {1..60}; do
  CALL_DETAIL=$(curl -s -H "Authorization: Bearer $TOKEN" "$BASE_URL/api/v1/calls/$CALL_ID")
  STATUS=$(echo "$CALL_DETAIL" | jq -r '.status')
  if [[ "$STATUS" == "ready" || "$STATUS" == "failed" ]]; then
    break
  fi
  sleep 2
done

echo "Final status: $STATUS"
if [[ "$STATUS" != "ready" ]]; then
  echo "Call did not reach ready status"
  echo "$CALL_DETAIL" | jq
  exit 1
fi

echo "[5/6] Fetching tasks..."
TASKS_JSON=$(curl -s -H "Authorization: Bearer $TOKEN" "$BASE_URL/api/v1/tasks")
TASKS_COUNT=$(echo "$TASKS_JSON" | jq 'length')
if [[ "$TASKS_COUNT" -lt 1 ]]; then
  echo "Expected at least one task, got $TASKS_COUNT"
  echo "$TASKS_JSON" | jq
  exit 1
fi

echo "[6/6] Success: call ready and tasks created ($TASKS_COUNT)"
