#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
APP_NAME="EyeBreak"
BUNDLE_DIR="$PROJECT_DIR/build/${APP_NAME}.app"
CONTENTS_DIR="$BUNDLE_DIR/Contents"

echo "Building ${APP_NAME} (release)..."
cd "$PROJECT_DIR"
swift build -c release

echo "Creating app bundle..."
rm -rf "$BUNDLE_DIR"
mkdir -p "$CONTENTS_DIR/MacOS"
mkdir -p "$CONTENTS_DIR/Resources"

# Copy binary
cp ".build/release/${APP_NAME}" "$CONTENTS_DIR/MacOS/${APP_NAME}"

# Copy Info.plist
cp "Sources/${APP_NAME}/Info.plist" "$CONTENTS_DIR/Info.plist"

# Copy app icon
if [ -f "assets/icons/AppIcon.icns" ]; then
    cp "assets/icons/AppIcon.icns" "$CONTENTS_DIR/Resources/AppIcon.icns"
    # Add icon reference to Info.plist if not already present
    if ! grep -q "CFBundleIconFile" "$CONTENTS_DIR/Info.plist"; then
        sed -i '' 's|</dict>|    <key>CFBundleIconFile</key>\n    <string>AppIcon</string>\n</dict>|' "$CONTENTS_DIR/Info.plist"
    fi
fi

# Write PkgInfo
echo -n "APPL????" > "$CONTENTS_DIR/PkgInfo"

# Ad-hoc codesign (sufficient for local use and Login Items)
echo "Code signing..."
codesign --force --sign - --deep "$BUNDLE_DIR"

echo ""
echo "Bundle created: $BUNDLE_DIR"
echo ""
echo "To install:"
echo "  cp -r \"$BUNDLE_DIR\" /Applications/"
echo "  open /Applications/${APP_NAME}.app"
