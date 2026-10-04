#!/bin/bash
set -e

PROJECT_DIR="/Users/jensschneider/Documents/Gemini/GSVokabelGenerator"
cd "$PROJECT_DIR"

echo "=== 1. Building release binary with SPM ==="
swift build -c release

BUILD_TMP="/tmp/GSVokabelGenerator_build"
rm -rf "$BUILD_TMP"
mkdir -p "$BUILD_TMP"

APP_PATH="$BUILD_TMP/GSVokabelGenerator.app"
mkdir -p "$APP_PATH/Contents/MacOS"
mkdir -p "$APP_PATH/Contents/Resources/Assets"

echo "=== 2. Assembling App Bundle ==="
cp .build/release/GSVokabelGenerator "$APP_PATH/Contents/MacOS/"
chmod +x "$APP_PATH/Contents/MacOS/GSVokabelGenerator"

# Copy Info.plist and PkgInfo
cp dist/GSVokabelGenerator.app/Contents/Info.plist "$APP_PATH/Contents/Info.plist"
echo -n "APPL????" > "$APP_PATH/Contents/PkgInfo"

# Copy AppIcon.icns and AppIcon.png (Colorful 3D Grundschul-Icon)
cp App/Resources/AppIcon.icns "$APP_PATH/Contents/Resources/AppIcon.icns"
cp App/Resources/AppIcon.icns scratch/AppIcon.icns
cp App/Resources/Assets/AppIcon.png "$APP_PATH/Contents/Resources/AppIcon.png"

# Copy resources to Resources and Resources/Assets
cp -R App/Resources/Assets/* "$APP_PATH/Contents/Resources/" 2>/dev/null || true
cp -R App/Resources/Assets/* "$APP_PATH/Contents/Resources/Assets/" 2>/dev/null || true

# Copy SPM Resource bundle
if [ -d .build/release/GSVokabelGenerator_GSVokabelGenerator.bundle ]; then
    cp -R .build/release/GSVokabelGenerator_GSVokabelGenerator.bundle "$APP_PATH/Contents/Resources/"
fi

echo "=== 3. Cleaning Extended Attributes and Signing ==="
xattr -cr "$APP_PATH"
codesign --force --deep --sign - "$APP_PATH"
codesign --verify --verbose=2 "$APP_PATH"

echo "=== 4. Creating Distribution DMG ==="
DMG_ROOT="$BUILD_TMP/dmg_root"
mkdir -p "$DMG_ROOT"
cp -RX "$APP_PATH" "$DMG_ROOT/"
ln -s /Applications "$DMG_ROOT/Programme"
cp Handbuch.md "$DMG_ROOT/Benutzerhandbuch.md"

hdiutil create -volname "GSVokabelGenerator" \
    -srcfolder "$DMG_ROOT" \
    -ov -format UDZO \
    "$BUILD_TMP/GSVokabelGenerator-1.0.dmg"

echo "=== 5. Creating Distribution ZIP ==="
(cd "$BUILD_TMP" && zip -qry GSVokabelGenerator-v1.0-macOS.zip GSVokabelGenerator.app)

echo "=== 6. Deploying to dist/ ==="
mkdir -p dist
rm -rf dist/GSVokabelGenerator.app dist/GSVokabelGenerator-1.0.dmg dist/GSVokabelGenerator-v1.0-macOS.zip
cp -RX "$APP_PATH" dist/
cp "$BUILD_TMP/GSVokabelGenerator-1.0.dmg" dist/
cp "$BUILD_TMP/GSVokabelGenerator-v1.0-macOS.zip" dist/
touch dist/GSVokabelGenerator.app

echo "=== Packaging Complete! ==="
ls -lh dist/
