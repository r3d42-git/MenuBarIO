#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UNIVERSAL_ARCHITECTURES="arm64 x86_64"
TEST_ARCHITECTURE="${MENUBARUSB_TEST_ARCH:-$(uname -m)}"
APP_NAME="MenuBarUSB-TB"

case "$TEST_ARCHITECTURE" in
  arm64|x86_64) ;;
  *)
    echo "Unsupported macOS test architecture: $TEST_ARCHITECTURE" >&2
    exit 2
    ;;
esac

if [[ -n "${MENUBARUSB_VERIFY_DERIVED_DATA_PATH:-}" ]]; then
  DERIVED_DATA_PATH="$MENUBARUSB_VERIFY_DERIVED_DATA_PATH"
else
  DERIVED_DATA_PATH="$(mktemp -d "${TMPDIR:-/tmp}/menubarusb-verify.XXXXXX")"
fi

cd "$ROOT_DIR"
./script/privacy_audit.sh
swiftc -typecheck script/generate_dmg_background.swift
bash -n script/create_installer_dmg.sh script/release.sh script/publish_release.sh script/verify_entitlements.sh

xcodebuild test -quiet \
  -project MenuBarUSB.xcodeproj \
  -scheme MenuBarUSB \
  -configuration Debug \
  -destination "platform=macOS,arch=$TEST_ARCHITECTURE" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  CODE_SIGNING_ALLOWED=NO

xcodebuild analyze -quiet \
  -project MenuBarUSB.xcodeproj \
  -scheme MenuBarUSB \
  -configuration Release \
  -destination "platform=macOS,arch=$TEST_ARCHITECTURE" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  CODE_SIGN_IDENTITY=- \
  CODE_SIGN_STYLE=Manual \
  DEVELOPMENT_TEAM=''

xcodebuild build -quiet \
  -project MenuBarUSB.xcodeproj \
  -scheme MenuBarUSB \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  ARCHS="$UNIVERSAL_ARCHITECTURES" \
  ONLY_ACTIVE_ARCH=NO \
  CODE_SIGN_IDENTITY=- \
  CODE_SIGN_STYLE=Manual \
  DEVELOPMENT_TEAM=''

APP_PATH="$DERIVED_DATA_PATH/Build/Products/Release/$APP_NAME.app"
if [[ ! -d "$APP_PATH" ]]; then
  echo "Universal build did not create the expected app bundle: $APP_PATH" >&2
  exit 1
fi

codesign --verify --deep --strict --verbose=2 "$APP_PATH"
for architecture in $UNIVERSAL_ARCHITECTURES; do
  lipo "$APP_PATH/Contents/MacOS/$APP_NAME" -verify_arch "$architecture"
done

echo "Tests, static analysis, and the Universal build passed."
