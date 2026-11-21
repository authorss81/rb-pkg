#!/usr/bin/env bash
# Atomic Git Compare-and-Swap (CAS) Package Lease Claimer
# Usage: ./claim_lease.sh <proposed-name> <org-name> <worker-id>

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

RAW="${1:-}"
ORG="${2:-}"
WORKER="${3:-worker-0}"

if [ -z "$RAW" ] || [ -z "$ORG" ]; then
    echo "Usage: $0 <proposed-name> <org-name> [worker-id]" >&2
    exit 1
fi

CANONICAL=$("$SCRIPT_DIR/normalize_name.sh" "$RAW")
LEASE_FILE="$ROOT_DIR/leases/$CANONICAL.json"

mkdir -p "$ROOT_DIR/leases"

# Pull latest main with rebase to ensure up-to-date registry state
git -C "$ROOT_DIR" pull --rebase origin main --quiet || true

# Check availability
if ! "$SCRIPT_DIR/check_availability.sh" "$CANONICAL" > /dev/null; then
    echo "FAILED: '$CANONICAL' is not available."
    exit 1
fi

NOW=$(date +%s)
NOW_ISO=$(date -u +%Y-%m-%dT%H:%M:%SZ)

cat <<EOF > "$LEASE_FILE"
{
  "name": "$CANONICAL",
  "raw_name": "$RAW",
  "owner": "$ORG",
  "worker_id": "$WORKER",
  "leased_at_epoch": $NOW,
  "leased_at": "$NOW_ISO",
  "status": "reserved"
}
EOF

git -C "$ROOT_DIR" add "$LEASE_FILE"
git -C "$ROOT_DIR" commit -m "lease($ORG): reserve '$CANONICAL' for $WORKER [skip ci]" --quiet

# Atomic Git push with retry loop (max 3 attempts for non-conflicting concurrent commits)
MAX_RETRIES=3
ATTEMPT=1
while [ "$ATTEMPT" -le "$MAX_RETRIES" ]; do
    if git -C "$ROOT_DIR" push origin main --quiet 2>/dev/null; then
        echo "LEASE_SECURED: Successfully reserved '$CANONICAL' for $ORG ($WORKER)"
        exit 0
    else
        echo "Git push rejected. Checking if competing commit claimed '$CANONICAL'..."
        git -C "$ROOT_DIR" fetch origin main --quiet
        
        # Check if remote main already has a lease file for this package from another worker
        if git -C "$ROOT_DIR" show "origin/main:leases/$CANONICAL.json" &>/dev/null; then
            REMOTE_OWNER=$(git -C "$ROOT_DIR" show "origin/main:leases/$CANONICAL.json" | jq -r '.owner // "unknown"')
            if [ "$REMOTE_OWNER" != "$ORG" ]; then
                echo "COLLISION_DETECTED: '$CANONICAL' was claimed by '$REMOTE_OWNER' first. Yielding."
                git -C "$ROOT_DIR" reset --hard origin/main --quiet
                exit 2
            fi
        fi
        
        # Another worker claimed a DIFFERENT package; safe to rebase and retry
        git -C "$ROOT_DIR" rebase origin/main --quiet || {
            git -C "$ROOT_DIR" rebase --abort --quiet 2>/dev/null || true
            git -C "$ROOT_DIR" reset --hard origin/main --quiet
            exit 1
        }
        ATTEMPT=$((ATTEMPT + 1))
    fi
done

echo "FAILED: Could not secure atomic lease for '$CANONICAL' after $MAX_RETRIES attempts."
exit 1
