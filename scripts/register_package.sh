#!/usr/bin/env bash
# Registers a verified package in the Global Sparse Registry Index
# Usage: ./register_package.sh <package-name> <org-name> <version> <blake3-hash>

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

RAW="${1:-}"
ORG="${2:-}"
VERSION="${3:-0.1.0}"
HASH="${4:-}"

if [ -z "$RAW" ] || [ -z "$ORG" ]; then
    echo "Usage: $0 <package-name> <org-name> [version] [blake3-hash]" >&2
    exit 1
fi

CANONICAL=$("$SCRIPT_DIR/normalize_name.sh" "$RAW")

LEN=${#CANONICAL}
if [ "$LEN" -le 2 ]; then
    PREFIX="$LEN"
elif [ "$LEN" -eq 3 ]; then
    PREFIX="3/${CANONICAL:0:1}"
else
    PREFIX="${CANONICAL:0:2}/${CANONICAL:2:2}"
fi

INDEX_DIR="$ROOT_DIR/index/$PREFIX"
INDEX_FILE="$INDEX_DIR/$CANONICAL.json"
LEASE_FILE="$ROOT_DIR/leases/$CANONICAL.json"

mkdir -p "$INDEX_DIR"

NOW_ISO=$(date -u +%Y-%m-%dT%H:%M:%SZ)

cat <<EOF > "$INDEX_FILE"
{
  "name": "$CANONICAL",
  "display_name": "$RAW",
  "org": "$ORG",
  "version": "$VERSION",
  "blake3": "$HASH",
  "published_at": "$NOW_ISO",
  "status": "published"
}
EOF

git -C "$ROOT_DIR" pull --rebase origin main --quiet || true
git -C "$ROOT_DIR" add "$INDEX_FILE"
if [ -f "$LEASE_FILE" ]; then
    git -C "$ROOT_DIR" rm -f "$LEASE_FILE" --quiet || true
fi

git -C "$ROOT_DIR" commit -m "publish($ORG): register $CANONICAL@$VERSION [skip ci]" --quiet
git -C "$ROOT_DIR" push origin main --quiet

echo "REGISTERED: '$CANONICAL' version $VERSION published to global index."
