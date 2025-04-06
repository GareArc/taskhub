#!/usr/bin/bash
# scripts/get_value.sh
# Usage: get_value.sh KEY SHARED_FILE

KEY="$1"
SHARED_FILE="$2"

if [ -f "$SHARED_FILE" ]; then
  grep "^${KEY}=" "$SHARED_FILE" | cut -d '=' -f2-
else
  echo "Shared file not found: $SHARED_FILE" >&2
  exit 1
fi
