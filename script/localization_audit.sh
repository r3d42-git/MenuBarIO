#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOCALIZATION_DIR="$ROOT_DIR/MenuBarIO/Localizable"
BASE_FILE="$LOCALIZATION_DIR/en.lproj/Localizable.strings"
AUDIT_DIR="$(mktemp -d "${TMPDIR:-/tmp}/menubario-localization-audit.XXXXXX")"

cleanup() {
  rm -rf "$AUDIT_DIR"
}
trap cleanup EXIT

extract_keys() {
  sed -nE 's/^"([^"]+)"[[:space:]]*=.*/\1/p' "$1"
}

LC_ALL=C extract_keys "$BASE_FILE" | sort > "$AUDIT_DIR/base-keys.txt"

for file in "$LOCALIZATION_DIR"/*.lproj/*.strings; do
  plutil -lint "$file" >/dev/null
done

for file in "$LOCALIZATION_DIR"/*.lproj/Localizable.strings; do
  locale="$(basename "$(dirname "$file")" .lproj)"
  keys_path="$AUDIT_DIR/$locale-keys.txt"
  LC_ALL=C extract_keys "$file" | sort > "$keys_path"

  duplicates="$(uniq -d "$keys_path")"
  if [[ -n "$duplicates" ]]; then
    echo "Localization audit failed: duplicate keys in $file:" >&2
    echo "$duplicates" >&2
    exit 1
  fi

  if ! diff -u "$AUDIT_DIR/base-keys.txt" "$keys_path" >/dev/null; then
    echo "Localization audit failed: key set differs from English in $file." >&2
    diff -u "$AUDIT_DIR/base-keys.txt" "$keys_path" >&2 || true
    exit 1
  fi
done

while IFS= read -r key; do
  if ! rg -F -q --glob '*.swift' "\"$key\"" "$ROOT_DIR/MenuBarIO"; then
    echo "Localization audit failed: unreferenced key: $key" >&2
    exit 1
  fi
done < "$AUDIT_DIR/base-keys.txt"

echo "Localization audit passed: syntax, key parity, duplicates, and Swift references are valid."
