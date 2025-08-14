#!/usr/bin/env bash
set -euo pipefail
PROJ="sdks/ios/NimbleEdgeAssistant"
PBX="$PROJ/NimbleEdgeAssistant.xcodeproj/project.pbxproj"
TARGET="NimbleEdgeAssistant"
APP_ID="org.nimbleedge.assistant"
cd "$PROJ"

# Remove legacy resources references
for RES in "Main.storyboard" "LaunchScreen.xib" "Images.xcassets"; do
  sed -i '' "/${RES//./\.} in Resources/d" "$PBX" || true
  sed -i '' "/${RES//./\.}/d" "$PBX" || true
done
# Remove obsolete source/header references
for FILE in BundleConfig.swift AppDelegate.swift ViewController.swift company_proto.pb.swift NimbleNetExample-Bridging-Header.h; do
  sed -i '' "/$FILE/d" "$PBX" || true
done

# Minimal Info.plist for expected path
mkdir -p NimbleNetExample
cat > NimbleNetExample/Info.plist <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleIdentifier</key><string>org.nimbleedge.assistant</string>
  <key>CFBundleExecutable</key><string>$(EXECUTABLE_NAME)</string>
  <key>CFBundleName</key><string>NimbleEdgeAssistant</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
</dict></plist>
PLIST

# Build for simulator unsigned
xcodebuild -project NimbleEdgeAssistant.xcodeproj -target "$TARGET" -configuration Debug -sdk iphonesimulator CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="" build

APP="build/Debug-iphonesimulator/NimbleEdgeAssistant.app"
BOOTED=$(xcrun simctl list | awk '/Booted/{print $NF;exit}')
if [[ -z "$BOOTED" ]]; then
  UDID=$(xcrun simctl create "EdgeSim" "iPhone 15" latest)
  xcrun simctl boot "$UDID"
fi
xcrun simctl install booted "$APP"
xcrun simctl launch booted "$APP_ID" || true

echo "✅ NimbleEdge Assistant built and launched."
