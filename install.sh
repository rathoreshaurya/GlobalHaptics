#!/bin/bash
set -e

PROJECT_DIR="/Users/shauryarathore/Documents/GlobalHaptics"
APP_NAME="GlobalHaptics.app"
DEST_DIR="/Applications"

echo "🔨 Building GlobalHaptics (Release)..."
cd "$PROJECT_DIR"
xcodebuild -project GlobalHaptics.xcodeproj -scheme GlobalHaptics -configuration Release -derivedDataPath "$PROJECT_DIR/build" clean build > /dev/null

BUILD_APP_PATH="$PROJECT_DIR/build/Build/Products/Release/$APP_NAME"

if [ ! -d "$BUILD_APP_PATH" ]; then
    echo "❌ Error: Could not locate built $APP_NAME bundle at $BUILD_APP_PATH"
    exit 1
fi

echo "📦 Found built app at: $BUILD_APP_PATH"

echo "🛑 Stopping any currently running instance of GlobalHaptics..."
pkill -f "GlobalHaptics" || true

echo "🚚 Installing $APP_NAME to $DEST_DIR..."
rm -rf "$DEST_DIR/$APP_NAME"
cp -R "$BUILD_APP_PATH" "$DEST_DIR/$APP_NAME"

echo "🔐 Ad-hoc code signing $DEST_DIR/$APP_NAME..."
codesign --force --deep --sign - "$DEST_DIR/$APP_NAME"

echo "🚀 Launching GlobalHaptics independently from $DEST_DIR/$APP_NAME..."
open "$DEST_DIR/$APP_NAME"

echo "✅ Done! GlobalHaptics is now running independently in your menu bar (⚡️)."
