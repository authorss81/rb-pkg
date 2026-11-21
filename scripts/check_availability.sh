#!/usr/bin/env bash
# Zero-Token Package Availability & Collision Checker
# Usage: ./check_availability.sh <proposed-name>

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

RAW="${1:-}"
if [ -z "$RAW" ]; then
    echo "Usage: $0 <package-name>" >&2
    exit 1
fi

CANONICAL=$("$SCRIPT_DIR/normalize_name.sh" "$RAW")

# Calculate 2-character sparse prefix (e.g. 'vector2d' -> 've/ct/vector2d.json')
LEN=${#CANONICAL}
if [ "$LEN" -le 2 ]; then
    PREFIX="$LEN"
elif [ "$LEN" -eq 3 ]; then
    PREFIX="3/${CANONICAL:0:1}"
else
    PREFIX="${CANONICAL:0:2}/${CANONICAL:2:2}"
fi

INDEX_FILE="$ROOT_DIR/index/$PREFIX/$CANONICAL.json"
LEASE_FILE="$ROOT_DIR/leases/$CANONICAL.json"

if [ -f "$INDEX_FILE" ]; then
    echo "TAKEN: Package '$RAW' collides with canonical registered package '$CANONICAL' in $INDEX_FILE"
    exit 1
fi

if [ -f "$LEASE_FILE" ]; then
    # Check if lease expired (e.g., > 4 hours old)
    NOW=$(date +%s)
    LEASE_TIME=$(jq -r '.leased_at_epoch // 0' "$LEASE_FILE" 2>/dev/null || echo 0)
    EXPIRES_AFTER=14400 # 4 hours in seconds
    if [ $((NOW - LEASE_TIME)) -lt $EXPIRES_AFTER ]; then
        OWNER=$(jq -r '.owner // "unknown"' "$LEASE_FILE")
        echo "LEASED: Package '$RAW' is currently leased by '$OWNER' (canonical: '$CANONICAL')"
        exit 2
    else
        echo "EXPIRED_LEASE: Previous lease for '$CANONICAL' has expired. Available for reclamation."
        exit 0
    fi
fi

echo "AVAILABLE: '$CANONICAL' is free to claim."
exit 0
