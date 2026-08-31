#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 VERSION" >&2
  exit 2
fi

VERSION="$1"
: "${MENUBARIO_TEAM_ID:=G6JH37W285}"
: "${MENUBARIO_SIGNING_IDENTITY:?Set the Developer ID Application signing identity.}"
: "${MENUBARIO_NOTARY_PROFILE:=MenuBarUSB-TB-notary}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PRODUCT_NAME="MenuBarIO"
BUNDLE_IDENTIFIER="de.r3d.menubarusb.tb"
# Distribution is deliberately Universal. Do not make this configurable: a
# release must contain both supported Mac architectures.
ARCHITECTURES="arm64 x86_64"
VOLUME_NAME="$PRODUCT_NAME installieren"
RELEASE_DIR="${MENUBARIO_RELEASE_DIR:-$ROOT_DIR/.release/$VERSION}"
ARCHIVE_PATH="$RELEASE_DIR/$PRODUCT_NAME.xcarchive"
APP_PATH="$ARCHIVE_PATH/Products/Applications/$PRODUCT_NAME.app"
APP_NOTARY_PATH="$RELEASE_DIR/$PRODUCT_NAME-notary.zip"
STAGING_DIR="$RELEASE_DIR/staging"
DMG_PATH="$RELEASE_DIR/$PRODUCT_NAME-$VERSION-mac.dmg"
CHECKSUM_PATH="$DMG_PATH.sha256"
ENTITLEMENTS_PATH="$RELEASE_DIR/effective-entitlements.plist"
SIGNATURE_PATH="$RELEASE_DIR/signature-details.txt"

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
  -project MenuBarIO.xcodeproj \
  -scheme MenuBarIO \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  -archivePath "$ARCHIVE_PATH" \
  ARCHS="$ARCHITECTURES" \
  ONLY_ACTIVE_ARCH=NO \
  CODE_SIGN_STYLE=Manual \
  CODE_SIGN_IDENTITY="$MENUBARIO_SIGNING_IDENTITY" \
  DEVELOPMENT_TEAM="$MENUBARIO_TEAM_ID" \
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
bash "$ROOT_DIR/script/verify_entitlements.sh" "$ENTITLEMENTS_PATH"

for architecture in $ARCHITECTURES; do
  lipo "$APP_PATH/Contents/MacOS/$PRODUCT_NAME" -verify_arch "$architecture"
done

# Notarize and staple the app before it is copied into the installer. The DMG
# receives its own independent ticket after packaging.
ditto -c -k --keepParent "$APP_PATH" "$APP_NOTARY_PATH"
xcrun notarytool submit "$APP_NOTARY_PATH" --keychain-profile "$MENUBARIO_NOTARY_PROFILE" --wait
xcrun stapler staple "$APP_PATH"
xcrun stapler validate "$APP_PATH"
spctl --assess --type execute --verbose=4 "$APP_PATH"

mkdir -p "$STAGING_DIR"
ditto "$APP_PATH" "$STAGING_DIR/$PRODUCT_NAME.app"
ditto "$ROOT_DIR/LICENSE" "$STAGING_DIR/LICENSE"
"$ROOT_DIR/script/create_installer_dmg.sh" \
  "$STAGING_DIR" \
  "$DMG_PATH" \
  "$VOLUME_NAME" \
  "$PRODUCT_NAME.app" \
  "Programme"

codesign --force --sign "$MENUBARIO_SIGNING_IDENTITY" --timestamp "$DMG_PATH"
codesign --verify --verbose=2 "$DMG_PATH"
xcrun notarytool submit "$DMG_PATH" --keychain-profile "$MENUBARIO_NOTARY_PROFILE" --wait
xcrun stapler staple "$DMG_PATH"
"$ROOT_DIR/script/verify_release.sh" "$VERSION" "$DMG_PATH"

(
  cd "$RELEASE_DIR"
  shasum -a 256 "$(basename "$DMG_PATH")" > "$(basename "$CHECKSUM_PATH")"
  shasum -a 256 -c "$(basename "$CHECKSUM_PATH")"
)

echo "Verified notarized release: $DMG_PATH"
echo "SHA-256 checksum: $CHECKSUM_PATH"
