#!/bin/bash
# Builds Driftpad.app and a DMG in the dist/ folder.
# Usage: ./package.sh
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="Driftpad"
VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" Packaging/Info.plist)
DIST="dist"
APP="$DIST/$APP_NAME.app"
BIN="$APP/Contents/MacOS/$APP_NAME"

echo "→ Building for Apple Silicon…"
swift build -c release --arch arm64

rm -rf "$DIST"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

echo "→ Building for Intel…"
if swift build -c release --arch x86_64; then
    # One binary that runs on both kinds of Mac
    lipo -create \
        ".build/arm64-apple-macosx/release/$APP_NAME" \
        ".build/x86_64-apple-macosx/release/$APP_NAME" \
        -output "$BIN"
else
    echo "  Intel build failed; packaging for Apple Silicon only."
    cp ".build/arm64-apple-macosx/release/$APP_NAME" "$BIN"
fi

echo "→ Assembling $APP_NAME.app…"
cp Packaging/Info.plist "$APP/Contents/"
cp Packaging/AppIcon.icns "$APP/Contents/Resources/"
cp Sources/Driftpad/Resources/TrayIconTemplate*.png "$APP/Contents/Resources/"

echo "→ Signing (ad-hoc)…"
codesign --force --deep --sign - "$APP"

echo "→ Creating DMG…"
STAGE=$(mktemp -d)
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"   # drag-to-install shortcut
hdiutil create -volname "$APP_NAME" -srcfolder "$STAGE" -ov -format UDZO \
    "$DIST/$APP_NAME-$VERSION.dmg" > /dev/null
rm -rf "$STAGE"

echo "✓ Done: $DIST/$APP_NAME-$VERSION.dmg"