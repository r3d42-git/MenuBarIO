#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UNIVERSAL_ARCHITECTURES="arm64 x86_64"
TEST_ARCHITECTURE="${MENUBARIO_TEST_ARCH:-$(uname -m)}"
APP_NAME="MenuBarIO"

case "$TEST_ARCHITECTURE" in
  arm64|x86_64) ;;
  *)
    echo "Unsupported macOS test architecture: $TEST_ARCHITECTURE" >&2
    exit 2
    ;;
esac

if [[ -n "${MENUBARIO_VERIFY_DERIVED_DATA_PATH:-}" ]]; then
  DERIVED_DATA_PATH="$MENUBARIO_VERIFY_DERIVED_DATA_PATH"
else
  DERIVED_DATA_PATH="$(mktemp -d "${TMPDIR:-/tmp}/menubario-verify.XXXXXX")"
fi

cd "$ROOT_DIR"

DEPLOYMENT_TARGETS="$(
  sed -nE 's/.*MACOSX_DEPLOYMENT_TARGET = ([0-9.]+);/\1/p' MenuBarIO.xcodeproj/project.pbxproj \
    | sort -u
)"
if [[ "$DEPLOYMENT_TARGETS" != "13.0" ]]; then
  echo "Deployment-target audit failed: expected only macOS 13.0, found: $DEPLOYMENT_TARGETS" >&2
  exit 1
fi

PRODUCT_VERSION="$(sed -nE 's/.*MARKETING_VERSION = ([0-9.]+);/\1/p' MenuBarIO.xcodeproj/project.pbxproj | sort -u)"
./script/verify_license_material.sh "$ROOT_DIR" "$PRODUCT_VERSION"

./script/privacy_audit.sh
./script/localization_audit.sh
swiftc -typecheck script/generate_dmg_background.swift
xcrun swift-format lint --recursive --configuration .swift-format MenuBarIO MenuBarIOTests
bash -n \
  script/create_installer_dmg.sh \
  script/localization_audit.sh \
  script/release.sh \
  script/publish_release.sh \
  script/verify_release.sh \
  script/verify_entitlements.sh \
  script/verify_license_material.sh

xcodebuild test -quiet \
  -project MenuBarIO.xcodeproj \
  -scheme MenuBarIO \
  -configuration Debug \
  -destination "platform=macOS,arch=$TEST_ARCHITECTURE" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  CODE_SIGNING_ALLOWED=NO

xcodebuild analyze -quiet \
  -project MenuBarIO.xcodeproj \
  -scheme MenuBarIO \
  -configuration Release \
  -destination "platform=macOS,arch=$TEST_ARCHITECTURE" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  CODE_SIGN_IDENTITY=- \
  CODE_SIGN_STYLE=Manual \
  DEVELOPMENT_TEAM=''

# Exercise archive-specific installation paths before Developer ID signing.
ARCHIVE_PATH="$DERIVED_DATA_PATH/$APP_NAME-verification.xcarchive"
xcodebuild archive -quiet \
  -project MenuBarIO.xcodeproj \
  -scheme MenuBarIO \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  -archivePath "$ARCHIVE_PATH" \
  ARCHS="$UNIVERSAL_ARCHITECTURES" \
  ONLY_ACTIVE_ARCH=NO \
  CODE_SIGN_IDENTITY=- \
  CODE_SIGN_STYLE=Manual \
  DEVELOPMENT_TEAM=''

APP_PATH="$ARCHIVE_PATH/Products/Applications/$APP_NAME.app"
if [[ ! -d "$APP_PATH" ]]; then
  echo "Universal archive did not create the expected app bundle: $APP_PATH" >&2
  exit 1
fi

./script/verify_license_material.sh "$APP_PATH/Contents/Resources/Licenses" "$PRODUCT_VERSION"
codesign --verify --deep --strict --verbose=2 "$APP_PATH"
for architecture in $UNIVERSAL_ARCHITECTURES; do
  lipo "$APP_PATH/Contents/MacOS/$APP_NAME" -verify_arch "$architecture"
done

echo "Tests, static analysis, and the Universal archive passed."
