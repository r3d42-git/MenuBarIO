#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "usage: $0 VERSION DMG_PATH" >&2
  exit 2
fi

VERSION="$1"
DMG_PATH="$2"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PRODUCT_NAME="MenuBarUSB-TB"
BUNDLE_IDENTIFIER="de.r3d.menubarusb.tb"
TEAM_IDENTIFIER="G6JH37W285"
APPLICATIONS_LINK_NAME="Programme"
ARCHITECTURES="arm64 x86_64"
MOUNT_DIR=""
ENTITLEMENTS_PATH=""

cleanup() {
  if [[ -n "$MOUNT_DIR" && -d "$MOUNT_DIR" ]]; then
    hdiutil detach "$MOUNT_DIR" -quiet >/dev/null 2>&1 || true
    rmdir "$MOUNT_DIR" >/dev/null 2>&1 || true
  fi
  if [[ -n "$ENTITLEMENTS_PATH" && -f "$ENTITLEMENTS_PATH" ]]; then
    rm -f "$ENTITLEMENTS_PATH"
  fi
}
trap cleanup EXIT

if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Invalid release version: $VERSION" >&2
  exit 2
fi
if [[ ! -f "$DMG_PATH" ]]; then
  echo "Release DMG does not exist: $DMG_PATH" >&2
  exit 1
fi

codesign --verify --verbose=2 "$DMG_PATH"
hdiutil verify "$DMG_PATH"
xcrun stapler validate "$DMG_PATH"
spctl --assess --type open --context context:primary-signature --verbose=4 "$DMG_PATH"

MOUNT_DIR="$(mktemp -d /private/tmp/menubarusb-release-verify.XXXXXX)"
hdiutil attach -readonly -nobrowse -mountpoint "$MOUNT_DIR" "$DMG_PATH" >/dev/null
APP_PATH="$MOUNT_DIR/$PRODUCT_NAME.app"
if [[ ! -d "$APP_PATH" ]]; then
  echo "Installer DMG is missing $PRODUCT_NAME.app." >&2
  exit 1
fi

codesign --verify --deep --strict --verbose=2 "$APP_PATH"
SIGNATURE_DETAILS="$(codesign -dvvv "$APP_PATH" 2>&1)"
if ! rg -q "^Identifier=$BUNDLE_IDENTIFIER$" <<<"$SIGNATURE_DETAILS"; then
  echo "Release app has the wrong bundle identifier." >&2
  exit 1
fi
if ! rg -q "^TeamIdentifier=$TEAM_IDENTIFIER$" <<<"$SIGNATURE_DETAILS"; then
  echo "Release app has the wrong signing team." >&2
  exit 1
fi
if ! rg -q '^CodeDirectory .*flags=.*\(runtime\)' <<<"$SIGNATURE_DETAILS"; then
  echo "Release app is missing the Hardened Runtime." >&2
  exit 1
fi

ENTITLEMENTS_PATH="$(mktemp /private/tmp/menubarusb-release-entitlements.XXXXXX)"
codesign -d --entitlements :- "$APP_PATH" > "$ENTITLEMENTS_PATH" 2>/dev/null
bash "$ROOT_DIR/script/verify_entitlements.sh" "$ENTITLEMENTS_PATH"

for architecture in $ARCHITECTURES; do
  lipo "$APP_PATH/Contents/MacOS/$PRODUCT_NAME" -verify_arch "$architecture"
done

APP_VERSION="$(plutil -extract CFBundleShortVersionString raw "$APP_PATH/Contents/Info.plist")"
if [[ "$APP_VERSION" != "$VERSION" ]]; then
  echo "Release app version $APP_VERSION does not match expected version $VERSION." >&2
  exit 1
fi

xcrun stapler validate "$APP_PATH"
spctl --assess --type execute --verbose=4 "$APP_PATH"

if [[ ! -L "$MOUNT_DIR/$APPLICATIONS_LINK_NAME" || "$(readlink "$MOUNT_DIR/$APPLICATIONS_LINK_NAME")" != "/Applications" ]]; then
  echo "Installer DMG is missing the $APPLICATIONS_LINK_NAME link to /Applications." >&2
  exit 1
fi
if [[ ! -f "$MOUNT_DIR/.background/installer-background.png" || ! -f "$MOUNT_DIR/LICENSE" ]]; then
  echo "Installer DMG is missing its required background or license." >&2
  exit 1
fi

echo "Verified release DMG and enclosed app: $DMG_PATH"
