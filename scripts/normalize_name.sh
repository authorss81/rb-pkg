#!/usr/bin/env bash
# Normalizes any package name to its canonical unique key:
# 1. Lowercase
# 2. Replaces '-', '.', and spaces with '_'
# 3. Collapses multiple consecutive '_' into a single '_'
# 4. Strips leading and trailing '_'

RAW="${1:-}"
if [ -z "$RAW" ]; then
    echo "Usage: $0 <package-name>" >&2
    exit 1
fi

CANONICAL=$(echo "$RAW" | tr '[:upper:]' '[:lower:]' | sed -E 's/[-. ]+/_/g' | sed -E 's/^_+|_+$//g')
echo "$CANONICAL"
