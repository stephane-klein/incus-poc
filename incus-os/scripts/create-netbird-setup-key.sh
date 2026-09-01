#!/usr/bin/env bash
set -e

cd "$(dirname "$0")/../"

NETBIRD_API_URL="${NETBIRD_API_URL:-https://api.netbird.io}"
SETUP_KEY_NAME="${SETUP_KEY_NAME:-incus1.homelab.stephane-klein.info}"
SETUP_KEY_GROUP="${SETUP_KEY_GROUP:-homelab-servers}"
SETUP_KEY_TYPE="${SETUP_KEY_TYPE:-reusable}"
SETUP_KEY_EXPIRES_IN="${SETUP_KEY_EXPIRES_IN:-604800}" # 7 days
SETUP_KEY_USAGE_LIMIT="${SETUP_KEY_USAGE_LIMIT:-0}"

PAT="$(gopass show netbird/apikey)"

GROUP_ID="$("$(mise which jq)" -r --arg name "$SETUP_KEY_GROUP" '
    .[] | select(.name == $name) | .id
' < <(curl -fsS "${NETBIRD_API_URL}/api/groups" -H "Authorization: Token ${PAT}"))"
[ -n "$GROUP_ID" ] || {
    echo "ERROR: group '$SETUP_KEY_GROUP' not found in NetBird" >&2
    exit 1
}

JSON="$("$(mise which jq)" -n \
    --arg name "$SETUP_KEY_NAME" \
    --arg type "$SETUP_KEY_TYPE" \
    --argjson expires_in "$SETUP_KEY_EXPIRES_IN" \
    --arg group_id "$GROUP_ID" \
    --argjson usage_limit "$SETUP_KEY_USAGE_LIMIT" \
    '{name: $name, type: $type, expires_in: $expires_in, auto_groups: [$group_id], usage_limit: $usage_limit, ephemeral: false, allow_extra_dns_labels: true}')"

RESPONSE="$(curl -fsS -X POST "${NETBIRD_API_URL}/api/setup-keys" \
    -H 'Accept: application/json' \
    -H 'Content-Type: application/json' \
    -H "Authorization: Token ${PAT}" \
    -d "$JSON")"

KEY="$(printf '%s' "$RESPONSE" | "$(mise which jq)" -r '.key')"

[ -n "$KEY" ] && [ "$KEY" != "null" ] || {
    echo "ERROR: no 'key' field in NetBird API response" >&2
    exit 1
}

printf '%s\n' "$KEY" | gopass insert --force "netbird/setup-keys/${SETUP_KEY_NAME}"

echo "Created NetBird setup key '$SETUP_KEY_NAME' (${SETUP_KEY_TYPE}, usage limit ${SETUP_KEY_USAGE_LIMIT}) and stored it in gopass netbird/setup-keys/${SETUP_KEY_NAME}"
