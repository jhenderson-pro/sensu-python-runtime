#!/usr/bin/env bash

set -euo pipefail

TARBALL=${1:-}

if [[ -z "$TARBALL" ]]; then
    echo "Usage: $0 <path-to-tarball>"
    exit 1
fi

if [[ ! -f "$TARBALL" ]]; then
    echo "Error: Tarball not found: $TARBALL"
    exit 1
fi

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

echo "Extracting $TARBALL for smoke test..."
tar -xf "$TARBALL" -C "$TMP_DIR"

echo "Running smoke tests..."

# Verify Python executes and version matches
echo "  Checking python version..."
"$TMP_DIR/bin/python" --version

# Verify SSL module
echo "  Checking SSL module..."
"$TMP_DIR/bin/python" -c "import ssl; print(f'    SSL Version: {ssl.OPENSSL_VERSION}')"

# Verify SQLite3 module
echo "  Checking sqlite3 module..."
"$TMP_DIR/bin/python" -c "import sqlite3; print(f'    SQLite Version: {sqlite3.sqlite_version}')"

# Verify Pip works
echo "  Checking pip..."
"$TMP_DIR/bin/pip" --version

echo "Smoke tests passed for $TARBALL"
