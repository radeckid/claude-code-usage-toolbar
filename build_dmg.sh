#!/bin/bash
set -euo pipefail

APP_NAME="Claude Usage Bar"
SCHEME="ClaudeUsageBar"
BUILD_DIR="build"

# Version from argument or Info.plist
VERSION="${1:-}"
if [ -z "$VERSION" ]; then
    VERSION=$(defaults read "$(pwd)/ClaudeUsageBar/Info.plist" CFBundleShortVersionString 2>/dev/null || echo "1.0")
fi

DMG_NAME="ClaudeUsageBar-v${VERSION}.dmg"

echo "==> Building $APP_NAME v$VERSION..."

echo "==> Updating version in Info.plist..."
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" ClaudeUsageBar/Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $VERSION" ClaudeUsageBar/Info.plist

echo "==> Cleaning previous build..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo "==> Building $APP_NAME (Release)..."
xcodebuild \
    -project ClaudeUsageBar.xcodeproj \
    -scheme "$SCHEME" \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR/DerivedData" \
    -quiet \
    ONLY_ACTIVE_ARCH=NO

# Find the built .app
APP_PATH=$(find "$BUILD_DIR/DerivedData" -name "*.app" -type d | head -1)

if [ -z "$APP_PATH" ]; then
    echo "ERROR: Could not find built .app"
    exit 1
fi

echo "==> Found app: $APP_PATH"

# Create DMG staging directory
STAGING="$BUILD_DIR/dmg_staging"
rm -rf "$STAGING"
mkdir -p "$STAGING"

cp -R "$APP_PATH" "$STAGING/"
ln -s /Applications "$STAGING/Applications"

echo "==> Creating DMG..."
rm -f "$BUILD_DIR/$DMG_NAME"
hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$STAGING" \
    -ov \
    -format UDZO \
    "$BUILD_DIR/$DMG_NAME"

rm -rf "$STAGING"

echo ""
echo "==> Done! DMG created at: $BUILD_DIR/$DMG_NAME"
echo "    Version: $VERSION"
echo "    Size: $(du -h "$BUILD_DIR/$DMG_NAME" | cut -f1)"

# Upload to GitHub as release if --release flag is passed
if [[ "${2:-}" == "--release" ]]; then
    echo ""
    echo "==> Creating GitHub release v$VERSION..."
    git tag -a "v$VERSION" -m "Release v$VERSION"
    git push origin "v$VERSION"
    gh release create "v$VERSION" \
        "$BUILD_DIR/$DMG_NAME" \
        --title "v$VERSION" \
        --notes "Claude Usage Bar v$VERSION"
    echo "==> Release published: https://github.com/radeckid/claude-code-usage-toolbar/releases/tag/v$VERSION"
fi
