#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 5 ]]; then
  echo "usage: $0 STAGING_DIR OUTPUT_DMG VOLUME_NAME APP_NAME APPLICATIONS_LINK_NAME" >&2
  exit 2
fi

STAGING_DIR="$1"
OUTPUT_DMG="$2"
VOLUME_NAME="$3"
APP_NAME="$4"
APPLICATIONS_LINK_NAME="$5"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKGROUND_DIRECTORY="$STAGING_DIR/.background"
BACKGROUND_NAME="installer-background.png"
BACKGROUND_PATH="$BACKGROUND_DIRECTORY/$BACKGROUND_NAME"
WRITABLE_DMG="${OUTPUT_DMG%.dmg}.rw.dmg"
MOUNT_POINT=""

cleanup() {
  if [[ -n "$MOUNT_POINT" && -d "$MOUNT_POINT" ]]; then
    hdiutil detach "$MOUNT_POINT" -quiet >/dev/null 2>&1 || true
  fi
  if [[ -f "$WRITABLE_DMG" ]]; then
    rm -f "$WRITABLE_DMG"
  fi
}
trap cleanup EXIT

if [[ ! -d "$STAGING_DIR" ]]; then
  echo "Missing staging directory: $STAGING_DIR" >&2
  exit 1
fi

if [[ ! -d "$STAGING_DIR/$APP_NAME" ]]; then
  echo "Missing staged app bundle: $STAGING_DIR/$APP_NAME" >&2
  exit 1
fi

if [[ -e "$OUTPUT_DMG" || -e "$WRITABLE_DMG" ]]; then
  echo "Refusing to overwrite an existing DMG output." >&2
  exit 1
fi

if ! osascript -e 'tell application "Finder" to get name' >/dev/null 2>&1; then
  echo "Creating the custom DMG layout requires an unlocked macOS Finder session." >&2
  exit 1
fi

mkdir -p "$BACKGROUND_DIRECTORY"
swift "$ROOT_DIR/script/generate_dmg_background.swift" "$BACKGROUND_PATH"
ln -s /Applications "$STAGING_DIR/$APPLICATIONS_LINK_NAME"

hdiutil create \
  -volname "$VOLUME_NAME" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDRW \
  "$WRITABLE_DMG"

MOUNT_POINT="$(hdiutil attach -readwrite -noverify -noautoopen "$WRITABLE_DMG" | awk -F '\t' 'NF { last = $NF } END { print last }')"
if [[ ! -d "$MOUNT_POINT" ]]; then
  echo "Could not determine the writable DMG mount point." >&2
  exit 1
fi

osascript <<APPLESCRIPT
tell application "Finder"
  tell disk "$VOLUME_NAME"
    open
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set bounds of container window to {100, 100, 860, 520}
    set viewOptions to the icon view options of container window
    set arrangement of viewOptions to not arranged
    set icon size of viewOptions to 96
    set text size of viewOptions to 13
    set background picture of viewOptions to file ".background:$BACKGROUND_NAME"
    set position of item "$APP_NAME" of container window to {190, 220}
    set position of item "$APPLICATIONS_LINK_NAME" of container window to {570, 220}
    set position of item "LICENSE" of container window to {78, 360}
    set position of item "LICENSE.upstream" of container window to {275, 360}
    set position of item "NOTICE" of container window to {470, 360}
    set position of item "SOURCE.md" of container window to {665, 360}
    update without registering applications
    delay 1
    close
  end tell
end tell
APPLESCRIPT

sync
hdiutil detach "$MOUNT_POINT" -quiet
MOUNT_POINT=""

hdiutil convert \
  "$WRITABLE_DMG" \
  -format UDZO \
  -imagekey zlib-level=9 \
  -o "$OUTPUT_DMG" >/dev/null

rm -f "$WRITABLE_DMG"
echo "Created installer DMG: $OUTPUT_DMG"
