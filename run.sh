#!/bin/bash
# Build & run Nebula Stats on the iOS Simulator, no Xcode GUI needed.
#
#   ./run.sh                    # xcodegen generate -> build -> boot "iPhone 16 Pro" -> install -> launch
#   ./run.sh "iPad Pro 11-inch (M4)"   # target a different simulator by name
#   ./run.sh --clean            # wipe DerivedData first
#   ./run.sh --screenshot       # also save launch.png after launch
set -euo pipefail
cd "$(dirname "$0")"

SCHEME="NebulaStats"
# Bundle id comes from the single config file (Config/AppConfig.xcconfig).
BUNDLE_ID=$(sed -n 's/^PRODUCT_BUNDLE_IDENTIFIER *= *//p' Config/AppConfig.xcconfig | tr -d '[:space:]')
SIM_NAME="iPhone 16 Pro"
CLEAN=0
SCREENSHOT=0

for arg in "$@"; do
  case "$arg" in
    --clean)      CLEAN=1 ;;
    --screenshot) SCREENSHOT=1 ;;
    *)            SIM_NAME="$arg" ;;
  esac
done

if [[ $CLEAN -eq 1 ]]; then
  echo "==> Cleaning DerivedData"
  rm -rf ~/Library/Developer/Xcode/DerivedData/${SCHEME}-*
fi

echo "==> xcodegen generate"
xcodegen generate

SIM_UDID=$(xcrun simctl list devices available | grep -F "$SIM_NAME (" | head -1 | grep -oE '[0-9A-F-]{36}')
if [[ -z "$SIM_UDID" ]]; then
  echo "error: no available simulator named \"$SIM_NAME\". Pick one of:" >&2
  xcrun simctl list devices available | grep -E "iPhone|iPad" >&2
  exit 1
fi
echo "==> Simulator: $SIM_NAME ($SIM_UDID)"

xcrun simctl bootstatus "$SIM_UDID" -b

echo "==> Building"
BUILD_LOG=$(mktemp)
xcodebuild -project ${SCHEME}.xcodeproj -scheme "$SCHEME" \
  -destination "id=$SIM_UDID" -configuration Debug build > "$BUILD_LOG" 2>&1 || true
grep -E "error:|warning:|BUILD SUCCEEDED|BUILD FAILED" "$BUILD_LOG" || true
if ! grep -q "BUILD SUCCEEDED" "$BUILD_LOG"; then
  echo "error: build failed — full log at $BUILD_LOG" >&2
  exit 1
fi

APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -maxdepth 1 -iname "${SCHEME}-*" -print -quit)/Build/Products/Debug-iphonesimulator/${SCHEME}.app
if [[ ! -d "$APP_PATH" ]]; then
  echo "error: build product not found at $APP_PATH" >&2
  exit 1
fi

echo "==> Installing & launching"
xcrun simctl install "$SIM_UDID" "$APP_PATH"
xcrun simctl terminate "$SIM_UDID" "$BUNDLE_ID" 2>/dev/null || true
xcrun simctl launch "$SIM_UDID" "$BUNDLE_ID"
open -a Simulator --args -CurrentDeviceUDID "$SIM_UDID"

if [[ $SCREENSHOT -eq 1 ]]; then
  sleep 2
  xcrun simctl io "$SIM_UDID" screenshot launch.png
  echo "==> Saved launch.png"
fi

echo "==> Done"
