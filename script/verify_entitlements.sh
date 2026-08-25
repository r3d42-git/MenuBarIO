#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 ENTITLEMENTS_PATH" >&2
  exit 2
fi

entitlements_path="$1"
required_entitlements=(
  "com.apple.security.app-sandbox"
  "com.apple.security.device.usb"
)

if ! plutil -lint "$entitlements_path" >/dev/null; then
  echo "Entitlement verification failed: not a valid property list: $entitlements_path" >&2
  exit 1
fi

for entitlement in "${required_entitlements[@]}"; do
  value="$(/usr/libexec/PlistBuddy -c "Print :$entitlement" "$entitlements_path" 2>/dev/null || true)"
  if [[ "$value" != "true" ]]; then
    echo "Entitlement verification failed: required entitlement is missing or not enabled: $entitlement" >&2
    exit 1
  fi
done

actual_entitlements="$(
  /usr/libexec/PlistBuddy -c Print "$entitlements_path" |
    sed -nE 's/^[[:space:]]*([^[:space:]]+) = .*/\1/p'
)"
while IFS= read -r entitlement; do
  [[ -z "$entitlement" ]] && continue
  case "$entitlement" in
    "com.apple.security.app-sandbox"|"com.apple.security.device.usb") ;;
    *)
      echo "Entitlement verification failed: unexpected entitlement: $entitlement" >&2
      exit 1
      ;;
  esac
done <<< "$actual_entitlements"
