#!/usr/bin/env bash

set -euo pipefail

# Ensure we are in the project root
cd "$(dirname "$0")/.."

UPSTREAM_JSON="build/upstream.json"
CACHE_DIR="build/cache"

if [[ ! -f "$UPSTREAM_JSON" ]]; then
    echo "Error: $UPSTREAM_JSON not found."
    exit 1
fi

mkdir -p "$CACHE_DIR"

# Detect which shasum tool to use
if command -v sha256sum >/dev/null 2>&1; then
    SHA256SUM="sha256sum"
elif command -v shasum >/dev/null 2>&1; then
    SHA256SUM="shasum -a 256"
else
    echo "Error: Neither sha256sum nor shasum found."
    exit 1
fi

# Helper to parse JSON using python3 (to avoid jq dependency)
get_json_val() {
    python3 -c "import json, sys; d = json.load(sys.stdin); print($1)" < "$UPSTREAM_JSON"
}

TAG=$(get_json_val "d['tag']")

# Iterate over architectures/libc
for TARGET in "x86_64-unknown-linux-gnu" "x86_64-unknown-linux-musl"; do
    FILENAME=$(get_json_val "d['artifacts']['$TARGET']['filename']")
    EXPECTED_SHA=$(get_json_val "d['artifacts']['$TARGET']['sha256']")
    URL="https://github.com/astral-sh/python-build-standalone/releases/download/$TAG/$FILENAME"
    DEST="$CACHE_DIR/$FILENAME"

    echo "Checking $FILENAME..."

    # Idempotency check
    if [[ -f "$DEST" ]]; then
        ACTUAL_SHA=$($SHA256SUM "$DEST" | cut -d' ' -f1)
        if [[ "$ACTUAL_SHA" == "$EXPECTED_SHA" ]]; then
            echo "  Already cached and verified."
            continue
        else
            echo "  Cached file has incorrect checksum. Re-downloading..."
            rm "$DEST"
        fi
    fi

    echo "  Downloading from $URL..."
    curl -L -o "$DEST" "$URL"

    echo "  Verifying checksum..."
    ACTUAL_SHA=$($SHA256SUM "$DEST" | cut -d' ' -f1)
    if [[ "$ACTUAL_SHA" != "$EXPECTED_SHA" ]]; then
        echo "Error: Checksum mismatch for $FILENAME"
        echo "  Expected: $EXPECTED_SHA"
        echo "  Actual:   $ACTUAL_SHA"
        exit 1
    fi
    echo "  Verified."
done

echo "All upstream artifacts fetched and verified."
