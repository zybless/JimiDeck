#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
DERIVED_DATA="$ROOT_DIR/.build/ReleaseDerivedData"
APP_SOURCE="$DERIVED_DATA/Build/Products/Release/JimiDeck.app"
VERSION="0.1.0"
ARTIFACT_BASE="JimiDeck-${VERSION}-Alpha-macOS-universal"
ZIP_PATH="$DIST_DIR/${ARTIFACT_BASE}.zip"
DMG_PATH="$DIST_DIR/${ARTIFACT_BASE}.dmg"
CHECKSUM_PATH="$DIST_DIR/SHA256SUMS-macOS.txt"
STAGING_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/jimideck-release.XXXXXX")"

cleanup() {
    /bin/rm -rf "$STAGING_ROOT"
}
trap cleanup EXIT

mkdir -p "$DIST_DIR"
/bin/rm -f "$ZIP_PATH" "$DMG_PATH" "$CHECKSUM_PATH"

cd "$ROOT_DIR"
xcodegen generate
xcodebuild \
    -project JimiDeck.xcodeproj \
    -scheme JimiDeck \
    -configuration Release \
    -destination "generic/platform=macOS" \
    -derivedDataPath "$DERIVED_DATA" \
    ARCHS="arm64 x86_64" \
    ONLY_ACTIVE_ARCH=NO \
    CODE_SIGNING_ALLOWED=NO \
    build

ZIP_ROOT="$STAGING_ROOT/$ARTIFACT_BASE"
DMG_ROOT="$STAGING_ROOT/dmg"
mkdir -p "$ZIP_ROOT" "$DMG_ROOT"

/usr/bin/ditto "$APP_SOURCE" "$ZIP_ROOT/JimiDeck.app"
/usr/bin/ditto "$APP_SOURCE" "$DMG_ROOT/JimiDeck.app"
/usr/bin/ditto "$ROOT_DIR/Release/UNSIGNED-NOTICE.txt" "$ZIP_ROOT/README-FIRST.txt"
/usr/bin/ditto "$ROOT_DIR/Release/UNSIGNED-NOTICE.txt" "$DMG_ROOT/README-FIRST.txt"

/usr/bin/xattr -cr "$ZIP_ROOT/JimiDeck.app" "$DMG_ROOT/JimiDeck.app"
/usr/bin/codesign --force --deep --sign - --timestamp=none "$ZIP_ROOT/JimiDeck.app"
/usr/bin/codesign --force --deep --sign - --timestamp=none "$DMG_ROOT/JimiDeck.app"
/usr/bin/codesign --verify --deep --strict "$ZIP_ROOT/JimiDeck.app"

/usr/bin/ditto -c -k --sequesterRsrc --keepParent "$ZIP_ROOT" "$ZIP_PATH"
/bin/ln -s /Applications "$DMG_ROOT/Applications"
/usr/bin/hdiutil create \
    -volname "JimiDeck ${VERSION} Alpha" \
    -srcfolder "$DMG_ROOT" \
    -format UDZO \
    -ov \
    "$DMG_PATH"

cd "$DIST_DIR"
/usr/bin/shasum -a 256 "$(basename "$ZIP_PATH")" "$(basename "$DMG_PATH")" > "$CHECKSUM_PATH"

echo "Created:"
echo "  $ZIP_PATH"
echo "  $DMG_PATH"
echo "  $CHECKSUM_PATH"
