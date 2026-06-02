#!/usr/bin/env bash

set -euo pipefail

# Ensure we are in the project root
cd "$(dirname "$0")/.."

VERSION=${1:-0.2.0-beta.1}
UPSTREAM_JSON="build/upstream.json"
DIST_DIR="dist"
ASSET_YAML="$DIST_DIR/asset.yml"

if [[ ! -f "$UPSTREAM_JSON" ]]; then
    echo "Error: $UPSTREAM_JSON not found."
    exit 1
fi

# Helper to parse JSON using python3
get_json_val() {
    python3 -c "import json, sys; d = json.load(sys.stdin); print($1)" < "$UPSTREAM_JSON"
}

PY_VERSION=$(get_json_val "d['python_version']")

# Detect which shasum tool to use
if command -v sha512sum >/dev/null 2>&1; then
    SHA512SUM="sha512sum"
elif command -v shasum >/dev/null 2>&1; then
    SHA512SUM="shasum -a 512"
else
    echo "Error: Neither sha512sum nor shasum found."
    exit 1
fi

get_sha512() {
    local file=$1
    if [[ ! -f "$file" ]]; then
        echo "Error: File not found: $file" >&2
        return 1
    fi
    $SHA512SUM "$file" | cut -d' ' -f1
}

# Filenames
GLIBC_FILENAME="sensu-python-runtime_${VERSION}_python-${PY_VERSION}_linux_amd64_glibc.tar.gz"
MUSL_FILENAME="sensu-python-runtime_${VERSION}_python-${PY_VERSION}_linux_amd64_musl.tar.gz"

GLIBC_PATH="$DIST_DIR/$GLIBC_FILENAME"
MUSL_PATH="$DIST_DIR/$MUSL_FILENAME"

echo "Generating $ASSET_YAML..."

GLIBC_SHA=$(get_sha512 "$GLIBC_PATH")
MUSL_SHA=$(get_sha512 "$MUSL_PATH")

# Use a tag-based URL (vVERSION)
BASE_URL="https://github.com/sensu/sensu-python-runtime/releases/download/v${VERSION}"

cat <<EOF > "$ASSET_YAML"
---
type: Asset
api_version: core/v2
metadata:
  name: sensu-python-runtime
spec:
  builds:
    - url: $BASE_URL/$GLIBC_FILENAME
      sha512: $GLIBC_SHA
      filters:
        - entity.system.os == 'linux'
        - entity.system.arch == 'amd64'
        - entity.system.platform != 'alpine'
    
    - url: $BASE_URL/$MUSL_FILENAME
      sha512: $MUSL_SHA
      filters:
        - entity.system.os == 'linux'
        - entity.system.arch == 'amd64'
        - entity.system.platform == 'alpine'
EOF

echo "Successfully generated $ASSET_YAML"
