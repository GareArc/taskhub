#!/usr/bin/bash
# scripts/store_value.sh
# Usage: store_value.sh KEY VALUE SHARED_FILE
KEY="$1"
VALUE="$2"
SHARED_FILE="$3"


# Check if the shared file exists
if [ ! -f "$SHARED_FILE" ]; then
  # Ensure the shared file exists, create folder if necessary
    mkdir -p "$(dirname "$SHARED_FILE")"
    touch "$SHARED_FILE"
fi

# Append the new key-value pair
echo "${KEY}=${VALUE}" >> "$SHARED_FILE"
