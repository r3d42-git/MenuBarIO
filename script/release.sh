#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 VERSION" >&2
  exit 2
fi

VERSION="$1"
: "${MENUBARUSB_TEAM_ID:=G6JH37W285}"
: "${MENUBARUSB_SIGNING_IDENTITY:?Set the Developer ID Application signing identity.}"
: "${MENUBARUSB_NOTARY_PROFILE:=MenuBarUSB-TB-notary}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PRODUCT_NAME="MenuBarUSB-TB"
BUNDLE_IDENTIFIER="de.r3d.menubarusb.tb"
ARCHITECTURES="${MENUBARUSB_ARCHS:-arm64}"
RELEASE_DIR="${MENUBARUSB_RELEASE_DIR:-$ROOT_DIR/.release/$VERSION}"
ARCHIVE_PATH="$RELEASE_DIR/$PRODUCT_NAME.xcarchive"
APP_PATH="$ARCHIVE_PATH/Products/Applications/$PRODUCT_NAME.app"
STAGING_DIR="$RELEASE_DIR/staging"
DMG_PATH="$RELEASE_DIR/$PRODUCT_NAME-$VERSION-mac.dmg"
CHECKSUM_PATH="$DMG_PATH.sha256"
ENTITLEMENTS_PATH="$RELEASE_DIR/effective-entitlements.plist"
SIGNATURE_PATH="$RELEASE_DIR/signature-details.txt"
MOUNT_DIR=""

cleanup() {
  if [[ -n "$MOUNT_DIR" && -d "$MOUNT_DIR" ]]; then
    hdiutil detach "$MOUNT_DIR" -quiet >/dev/null 2>&1 || true
    rmdir "$MOUNT_DIR" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

cd "$ROOT_DIR"
if [[ -n "$(git status --porcelain=v1 --untracked-files=all)" ]]; then
  echo "Refusing to release with uncommitted or untracked nonignored changes." >&2
  echo "Commit, remove, or ignore them before creating an artifact." >&2
  exit 1
fi

if [[ -e "$RELEASE_DIR" ]]; then
  echo "Release directory already exists: $RELEASE_DIR" >&2
  echo "Choose a new version or remove that exact previous release directory manually." >&2
  exit 1
fi
mkdir -p "$RELEASE_DIR"

./script/verify.sh

xcodebuild archive \
  -project MenuBarUSB.xcodeproj \
  -scheme MenuBarUSB \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  -archivePath "$ARCHIVE_PATH" \
  ARCHS="$ARCHITECTURES" \
  ONLY_ACTIVE_ARCH=NO \
  CODE_SIGN_STYLE=Manual \
  CODE_SIGN_IDENTITY="$MENUBARUSB_SIGNING_IDENTITY" \
  DEVELOPMENT_TEAM="$MENUBARUSB_TEAM_ID" \
  MARKETING_VERSION="$VERSION" \
  PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_IDENTIFIER" \
  PRODUCT_NAME="$PRODUCT_NAME" \
  OTHER_CODE_SIGN_FLAGS='--timestamp'

if [[ ! -d "$APP_PATH" ]]; then
  echo "Expected app bundle was not created: $APP_PATH" >&2
  exit 1
fi

codesign --verify --deep --strict --verbose=2 "$APP_PATH"
codesign -dvv "$APP_PATH" > "$SIGNATURE_PATH" 2>&1
if ! rg -q 'flags=.*runtime' "$SIGNATURE_PATH"; then
  echo "Release app is missing the Hardened Runtime." >&2
  exit 1
fi
codesign -d --entitlements :- "$APP_PATH" > "$ENTITLEMENTS_PATH" 2>/dev/null
plutil -lint "$ENTITLEMENTS_PATH" >/dev/null
if /usr/libexec/PlistBuddy -c 'Print :com.apple.security.get-task-allow' "$ENTITLEMENTS_PATH" >/dev/null 2>&1; then
  echo "Release app must not contain com.apple.security.get-task-allow." >&2
  exit 1
fi

for architecture in $ARCHITECTURES; do
  lipo "$APP_PATH/Contents/MacOS/$PRODUCT_NAME" -verify_arch "$architecture"
done

mkdir -p "$STAGING_DIR"
ditto "$APP_PATH" "$STAGING_DIR/$PRODUCT_NAME.app"
ditto "$ROOT_DIR/LICENSE" "$STAGING_DIR/LICENSE"

hdiutil create \
  -volname "$PRODUCT_NAME $VERSION" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

codesign --force --sign "$MENUBARUSB_SIGNING_IDENTITY" --timestamp "$DMG_PATH"
codesign --verify --verbose=2 "$DMG_PATH"
xcrun notarytool submit "$DMG_PATH" --keychain-profile "$MENUBARUSB_NOTARY_PROFILE" --wait
xcrun stapler staple "$DMG_PATH"
xcrun stapler validate "$DMG_PATH"
hdiutil verify "$DMG_PATH"
spctl --assess --type open --context context:primary-signature --verbose=4 "$DMG_PATH"

MOUNT_DIR="$(mktemp -d /private/tmp/menubarusb-release-mount.XXXXXX)"
hdiutil attach -readonly -nobrowse -mountpoint "$MOUNT_DIR" "$DMG_PATH" >/dev/null
codesign --verify --deep --strict --verbose=2 "$MOUNT_DIR/$PRODUCT_NAME.app"

(
  cd "$RELEASE_DIR"
  shasum -a 256 "$(basename "$DMG_PATH")" > "$(basename "$CHECKSUM_PATH")"
  shasum -a 256 -c "$(basename "$CHECKSUM_PATH")"
)

echo "Verified notarized release: $DMG_PATH"
echo "SHA-256 checksum: $CHECKSUM_PATH"
