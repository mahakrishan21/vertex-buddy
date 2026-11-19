#!/bin/bash
# Builds ClaudeBuddy.app into ./build. Pass --install to copy it to ~/Applications and start it.
set -euo pipefail
cd "$(dirname "$0")"

swift build -c release
BIN=.build/release/ClaudeBuddy
APP=build/ClaudeBuddy.app

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/ClaudeBuddy"

# App icon, drawn from the sprite itself.
TMP=$(mktemp -d)
"$BIN" --snapshot "$TMP" >/dev/null
ICONSET="$TMP/AppIcon.iconset"
mkdir -p "$ICONSET"
for s in 16 32 128 256 512; do
  sips -z $s $s "$TMP/icon.png" --out "$ICONSET/icon_${s}x${s}.png" >/dev/null
  sips -z $((s * 2)) $((s * 2)) "$TMP/icon.png" --out "$ICONSET/icon_${s}x${s}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"
rm -rf "$TMP"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>Claude Buddy</string>
  <key>CFBundleDisplayName</key><string>Claude Buddy</string>
  <key>CFBundleIdentifier</key><string>local.claudebuddy</string>
  <key>CFBundleExecutable</key><string>ClaudeBuddy</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>2.0</string>
  <key>CFBundleVersion</key><string>2</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>LSUIElement</key><true/>
  <key>NSAppleEventsUsageDescription</key>
  <string>Claude Buddy switches to the Terminal or iTerm tab of the Claude session you click.</string>
</dict>
</plist>
PLIST

codesign --force --sign - "$APP" >/dev/null 2>&1
echo "Built $APP"

if [[ "${1:-}" == "--install" ]]; then
  mkdir -p "$HOME/Applications"
  pkill -x ClaudeBuddy 2>/dev/null || true
  rm -rf "$HOME/Applications/ClaudeBuddy.app"
  cp -R "$APP" "$HOME/Applications/"
  open "$HOME/Applications/ClaudeBuddy.app"
  echo "Installed to ~/Applications/ClaudeBuddy.app and started it"
fi
