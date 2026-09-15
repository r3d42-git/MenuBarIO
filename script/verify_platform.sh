#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 APP_PATH" >&2
  exit 2
fi

APP_PATH="$1"
ARCHITECTURES="$(lipo -archs "$APP_PATH/Contents/MacOS/MenuBarIO")"
if [[ "$ARCHITECTURES" != "arm64" ]]; then
  echo "Platform audit failed: expected only arm64, found: $ARCHITECTURES" >&2
  exit 1
fi
MINIMUM_VERSION="$(plutil -extract LSMinimumSystemVersion raw "$APP_PATH/Contents/Info.plist")"
if [[ "$MINIMUM_VERSION" != "15.0" ]]; then
  echo "Platform audit failed: expected macOS 15.0 minimum, found: $MINIMUM_VERSION" >&2
  exit 1
fi

echo "Verified Apple Silicon-only app with macOS 15.0 minimum: $APP_PATH"
