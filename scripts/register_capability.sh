#!/usr/bin/env bash
# Registers a Capability Concept into the central registry
# Usage: ./register_capability.sh <concept-id> <owner-org> <primary-package> <description>

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

CONCEPT="${1:-}"
OWNER="${2:-}"
PKG="${3:-}"
DESC="${4:-}"

if [ -z "$CONCEPT" ] || [ -z "$OWNER" ] || [ -z "$PKG" ]; then
    echo "Usage: $0 <concept-id> <owner-org> <primary-package> [description]" >&2
    exit 1
fi

CAP_DIR="$ROOT_DIR/capabilities"
mkdir -p "$CAP_DIR"

CAP_FILE="$CAP_DIR/$CONCEPT.json"

if [ -f "$CAP_FILE" ]; then
    EXISTING_OWNER=$(jq -r '.owner // "unknown"' "$CAP_FILE" 2>/dev/null || echo "unknown")
    if [ "$EXISTING_OWNER" != "$OWNER" ]; then
        echo "ERROR: Capability '$CONCEPT' already claimed by '$EXISTING_OWNER'" >&2
        exit 1
    fi
fi

cat <<EOF > "$CAP_FILE"
{
  "concept_id": "$CONCEPT",
  "owner": "$OWNER",
  "primary_package": "$PKG",
  "description": "$DESC",
  "registered_at_epoch": $(date +%s),
  "registered_at_utc": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

echo "REGISTERED_CAPABILITY: '$CONCEPT' -> '$PKG' ($OWNER)"
exit 0
