#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
WINDOWS_DIR="$ROOT_DIR/Windows"
DIST_DIR="$ROOT_DIR/dist/windows"
CHECKSUM_PATH="$DIST_DIR/SHA256SUMS-Windows.txt"

cd "$WINDOWS_DIR"
"$ROOT_DIR/Scripts/check_project_boundaries.sh"
npm ci
npm audit --audit-level=high
npm run check
CSC_IDENTITY_AUTO_DISCOVERY=false npm run dist:windows

cd "$DIST_DIR"
/usr/bin/shasum -a 256 \
    JimiDeck-0.2.0-Alpha-Windows-x64.exe \
    JimiDeck-0.2.0-Alpha-Windows-x64.zip \
    > "$CHECKSUM_PATH"

echo "Created:"
echo "  $DIST_DIR/JimiDeck-0.2.0-Alpha-Windows-x64.exe"
echo "  $DIST_DIR/JimiDeck-0.2.0-Alpha-Windows-x64.zip"
echo "  $CHECKSUM_PATH"
