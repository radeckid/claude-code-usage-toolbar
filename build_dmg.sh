#!/bin/bash
set -euo pipefail

APP_NAME="Claude Usage Bar"
SCHEME="ClaudeUsageBar"
BUILD_DIR="build"
GITHUB_REPO="radeckid/claude-code-usage-toolbar"

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

    # --- Sparkle: sign DMG with EdDSA ---
    echo "==> Signing DMG with Sparkle EdDSA..."

    # Locate sign_update: prefer SIGN_UPDATE_PATH env var, then search DerivedData
    if [ -n "${SIGN_UPDATE_PATH:-}" ]; then
        SIGN_UPDATE="$SIGN_UPDATE_PATH"
    else
        SIGN_UPDATE=$(find "$BUILD_DIR/DerivedData" -name "sign_update" -type f 2>/dev/null | head -1)
    fi

    if [ -z "$SIGN_UPDATE" ]; then
        echo "ERROR: Could not find Sparkle sign_update tool."
        echo "Set SIGN_UPDATE_PATH env var or ensure Sparkle is built."
        exit 1
    fi

    # sign_update reads private key from Keychain (or SPARKLE_KEY env var)
    SIGN_OUTPUT=$("$SIGN_UPDATE" "$BUILD_DIR/$DMG_NAME")
    echo "    Signature output: $SIGN_OUTPUT"

    EDDSA_SIGNATURE=$(echo "$SIGN_OUTPUT" | sed -n 's/.*sparkle:edSignature="\([^"]*\)".*/\1/p')
    FILE_LENGTH=$(stat -f%z "$BUILD_DIR/$DMG_NAME")
    DOWNLOAD_URL="https://github.com/$GITHUB_REPO/releases/download/v$VERSION/$DMG_NAME"
    PUB_DATE=$(date -u +"%a, %d %b %Y %H:%M:%S %z")

    # --- Sparkle: generate appcast.xml ---
    echo "==> Generating appcast.xml..."
    cat > "$BUILD_DIR/appcast.xml" << APPCAST_EOF
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" xmlns:dc="http://purl.org/dc/elements/1.1/">
  <channel>
    <title>Claude Usage Bar Updates</title>
    <link>https://github.com/$GITHUB_REPO</link>
    <description>Most recent changes with links to updates.</description>
    <language>en</language>
    <item>
      <title>Version $VERSION</title>
      <pubDate>$PUB_DATE</pubDate>
      <sparkle:version>$VERSION</sparkle:version>
      <sparkle:shortVersionString>$VERSION</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion>
      <enclosure
        url="$DOWNLOAD_URL"
        length="$FILE_LENGTH"
        type="application/octet-stream"
        sparkle:edSignature="$EDDSA_SIGNATURE"
      />
    </item>
  </channel>
</rss>
APPCAST_EOF

    echo "    Appcast: $BUILD_DIR/appcast.xml"

    # --- Create GitHub release with DMG + appcast ---
    echo "==> Creating GitHub release v$VERSION..."
    git tag -a "v$VERSION" -m "Release v$VERSION"
    git push origin "v$VERSION"
    gh release create "v$VERSION" \
        "$BUILD_DIR/$DMG_NAME" \
        "$BUILD_DIR/appcast.xml" \
        --title "v$VERSION" \
        --notes "Claude Usage Bar v$VERSION"
    echo "==> Release published: https://github.com/$GITHUB_REPO/releases/tag/v$VERSION"
fi
