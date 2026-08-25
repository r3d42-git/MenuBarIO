#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="MenuBarUSB-TB"
BUNDLE_ID="de.r3d.menubarusb.tb"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_ARCHITECTURE="${MENUBARUSB_BUILD_ARCH:-$(uname -m)}"
DERIVED_DATA_PATH="${MENUBARUSB_DERIVED_DATA_PATH:-${TMPDIR:-/tmp}/menubarusb-tb-derived-data}"
APP_BUNDLE="$DERIVED_DATA_PATH/Build/Products/Debug/$APP_NAME.app"

case "$TARGET_ARCHITECTURE" in
  arm64|x86_64) ;;
  *)
    echo "Unsupported macOS build architecture: $TARGET_ARCHITECTURE" >&2
    exit 2
    ;;
esac

pkill -x "$APP_NAME" >/dev/null 2>&1 || true

cd "$ROOT_DIR"
xcodebuild build -quiet \
  -project MenuBarUSB.xcodeproj \
  -scheme MenuBarUSB \
  -configuration Debug \
  -destination "platform=macOS,arch=$TARGET_ARCHITECTURE" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  CODE_SIGN_IDENTITY=- \
  CODE_SIGN_STYLE=Manual \
  DEVELOPMENT_TEAM='' \
  PRODUCT_NAME="$APP_NAME" \
  PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_ID"

open_app() {
  /usr/bin/open -n "$APP_BUNDLE"
}

case "$MODE" in
  run)
    open_app
    ;;
  --debug|debug)
    lldb -- "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --verify|verify)
    open_app
    sleep 1
    pgrep -x "$APP_NAME" >/dev/null
    ;;
  *)
    echo "usage: $0 [run|--debug|--logs|--verify]" >&2
    exit 2
    ;;
esac
