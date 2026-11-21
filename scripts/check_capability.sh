#!/usr/bin/env bash
# Zero-Token Capability Concept Checker
# Usage: ./check_capability.sh <concept-id>
# e.g.: ./check_capability.sh "math.linear_algebra.vector2d"

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

CONCEPT="${1:-}"
if [ -z "$CONCEPT" ]; then
    echo "Usage: $0 <concept-id>" >&2
    exit 1
fi

CAP_FILE="$ROOT_DIR/capabilities/$CONCEPT.json"

if [ -f "$CAP_FILE" ]; then
    OWNER=$(jq -r '.owner // "unknown"' "$CAP_FILE" 2>/dev/null || echo "unknown")
    PKG=$(jq -r '.primary_package // "unknown"' "$CAP_FILE" 2>/dev/null || echo "unknown")
    echo "CLAIMED: Capability '$CONCEPT' is already implemented by '$PKG' (owner: '$OWNER')"
    exit 1
fi

echo "AVAILABLE: Capability '$CONCEPT' is open for implementation."
exit 0
