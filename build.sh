#!/bin/bash
set -euo pipefail

APP_NAME="EyeBreak"
BUILD_DIR=".build"
APP_BUNDLE="${APP_NAME}.app"
CONTENTS_DIR="${APP_BUNDLE}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

echo "==> Building ${APP_NAME}..."
swift build -c release 2>&1

BINARY_PATH=$(swift build -c release --show-bin-path)/${APP_NAME}

if [ ! -f "$BINARY_PATH" ]; then
    echo "ERROR: Binary not found at ${BINARY_PATH}"
    exit 1
fi

echo "==> Creating ${APP_BUNDLE}..."
rm -rf "${APP_BUNDLE}"
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

cp "${BINARY_PATH}" "${MACOS_DIR}/${APP_NAME}"

# Copy app icon
cp assets/icons/AppIcon.icns "${RESOURCES_DIR}/AppIcon.icns"

cat > "${CONTENTS_DIR}/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>EyeBreak</string>
    <key>CFBundleIdentifier</key>
    <string>com.eyebreak.app</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleExecutable</key>
    <string>EyeBreak</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSAccessibilityUsageDescription</key>
    <string>EyeBreak needs accessibility access to monitor keyboard and mouse activity for tracking screen usage time.</string>
</dict>
</plist>
PLIST

echo "==> Done! Run with: open ${APP_BUNDLE}"
echo "    Or: ./${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"
