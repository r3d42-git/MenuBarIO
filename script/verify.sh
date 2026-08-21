#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ -n "${MENUBARUSB_VERIFY_DERIVED_DATA_PATH:-}" ]]; then
  DERIVED_DATA_PATH="$MENUBARUSB_VERIFY_DERIVED_DATA_PATH"
else
  DERIVED_DATA_PATH="$(mktemp -d "${TMPDIR:-/tmp}/menubarusb-verify.XXXXXX")"
fi

cd "$ROOT_DIR"
./script/privacy_audit.sh

xcodebuild test -quiet \
  -project MenuBarUSB.xcodeproj \
  -scheme MenuBarUSB \
  -configuration Debug \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  CODE_SIGN_IDENTITY=- \
  CODE_SIGN_STYLE=Manual \
  DEVELOPMENT_TEAM=''

xcodebuild analyze -quiet \
  -project MenuBarUSB.xcodeproj \
  -scheme MenuBarUSB \
  -configuration Release \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  CODE_SIGN_IDENTITY=- \
  CODE_SIGN_STYLE=Manual \
  DEVELOPMENT_TEAM=''

echo "Tests and static analysis passed."
