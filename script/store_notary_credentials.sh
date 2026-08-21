#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 APPLE_ID" >&2
  echo "Creates or validates the local MenuBarUSB-TB notarytool Keychain profile." >&2
  exit 2
fi

exec xcrun notarytool store-credentials 'MenuBarUSB-TB-notary' \
  --apple-id "$1" \
  --team-id 'G6JH37W285'
