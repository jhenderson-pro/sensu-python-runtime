#!/usr/bin/env bash

set -euo pipefail

# Ensure we are in the project root
cd "$(dirname "$0")/.."

LIBC=${1:-}
VERSION=${2:-0.2.0-beta.1}

if [[ -z "$LIBC" ]]; then
    echo "Usage: $0 <glibc|musl> [version]"
    exit 1
fi

UPSTREAM_JSON="build/upstream.json"
CACHE_DIR="build/cache"
DIST_DIR="dist"
BUILD_DIR="build/repackage_$LIBC"

if [[ ! -f "$UPSTREAM_JSON" ]]; then
    echo "Error: $UPSTREAM_JSON not found. Run build/fetch-upstream.sh first."
    exit 1
fi

# Helper to parse JSON using python3
get_json_val() {
    python3 -c "import json, sys; d = json.load(sys.stdin); print($1)" < "$UPSTREAM_JSON"
}

PY_VERSION=$(get_json_val "d['python_version']")

if [[ "$LIBC" == "glibc" ]]; then
    TARGET="x86_64-unknown-linux-gnu"
elif [[ "$LIBC" == "musl" ]]; then
    TARGET="x86_64-unknown-linux-musl"
else
    echo "Error: Invalid libc: $LIBC. Must be 'glibc' or 'musl'."
    exit 1
fi

FILENAME=$(get_json_val "d['artifacts']['$TARGET']['filename']")
SRC_TARBALL="$CACHE_DIR/$FILENAME"

if [[ ! -f "$SRC_TARBALL" ]]; then
    echo "Error: $SRC_TARBALL not found. Run build/fetch-upstream.sh first."
    exit 1
fi

echo "Repackaging $LIBC ($PY_VERSION)..."

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
mkdir -p "$DIST_DIR"

echo "  Extracting..."
tar -xf "$SRC_TARBALL" -C "$BUILD_DIR"

# Upstream layout is python/{bin,lib,include,share}
# We want {bin,lib,include,share} at the root.
echo "  Flattening layout..."
# Move contents of python/ to BUILD_DIR root
mv "$BUILD_DIR/python/"* "$BUILD_DIR/"
rmdir "$BUILD_DIR/python"

# Create new tarball
# sensu-python-runtime_<version>_python-<py-version>_linux_amd64_<libc>.tar.gz
OUT_FILENAME="sensu-python-runtime_${VERSION}_python-${PY_VERSION}_linux_amd64_${LIBC}.tar.gz"
OUT_PATH="$DIST_DIR/$OUT_FILENAME"

echo "  Packaging into $OUT_PATH..."
# We use -C BUILD_DIR and . to ensure the paths are at the root
tar -czf "$OUT_PATH" -C "$BUILD_DIR" .

echo "Successfully repackaged into $OUT_PATH"
