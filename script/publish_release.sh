#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 VERSION" >&2
  exit 2
fi

VERSION="$1"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPOSITORY="r3d42-git/MenuBarIO"
PRODUCT_NAME="MenuBarIO"
TAG="v$VERSION"
DMG_PATH="$ROOT_DIR/.release/$VERSION/$PRODUCT_NAME-$VERSION-mac.dmg"
CHECKSUM_PATH="$DMG_PATH.sha256"
RELEASE_NOTES_PATH="$ROOT_DIR/RELEASE_NOTES/$VERSION.md"
DOWNLOAD_DIR=""

cleanup() {
  if [[ -n "$DOWNLOAD_DIR" && -d "$DOWNLOAD_DIR" ]]; then
    rm -rf "$DOWNLOAD_DIR"
  fi
}
trap cleanup EXIT

if [[ ! -f "$DMG_PATH" ]]; then
  echo "Missing local notarized DMG: $DMG_PATH" >&2
  echo "Run ./script/release.sh $VERSION first." >&2
  exit 1
fi

if [[ ! -f "$RELEASE_NOTES_PATH" ]]; then
  echo "Missing release notes: $RELEASE_NOTES_PATH" >&2
  exit 1
fi

if [[ ! -f "$CHECKSUM_PATH" ]]; then
  echo "Missing DMG checksum: $CHECKSUM_PATH" >&2
  echo "Run ./script/release.sh $VERSION first." >&2
  exit 1
fi

cd "$ROOT_DIR"
if [[ -n "$(git status --porcelain=v1 --untracked-files=all)" ]]; then
  echo "Refusing to publish with uncommitted or untracked nonignored changes." >&2
  echo "Commit, remove, or ignore them before publishing." >&2
  exit 1
fi

if [[ "$(git remote get-url origin)" != "https://github.com/$REPOSITORY.git" ]]; then
  echo "origin does not point to $REPOSITORY." >&2
  exit 1
fi

if ! git ls-remote --exit-code --tags origin "refs/tags/$TAG" >/dev/null 2>&1; then
  echo "Remote tag $TAG is missing. Push the reviewed tag before publishing." >&2
  exit 1
fi

LOCAL_SHA256="$(shasum -a 256 "$DMG_PATH" | awk '{print $1}')"
CHECKSUM_SHA256="$(awk 'NF { print $1; exit }' "$CHECKSUM_PATH")"
if [[ "$CHECKSUM_SHA256" != "$LOCAL_SHA256" ]]; then
  echo "The recorded checksum does not match the local DMG." >&2
  exit 1
fi
"$ROOT_DIR/script/verify_release.sh" "$VERSION" "$DMG_PATH"

gh release create "$TAG" "$DMG_PATH" "$CHECKSUM_PATH" \
  --repo "$REPOSITORY" \
  --title "$PRODUCT_NAME $VERSION" \
  --notes-file "$RELEASE_NOTES_PATH" \
  --verify-tag

DOWNLOAD_DIR="$(mktemp -d /private/tmp/menubario-release-download.XXXXXX)"
gh release download "$TAG" \
  --repo "$REPOSITORY" \
  --pattern "$(basename "$DMG_PATH")" \
  --pattern "$(basename "$CHECKSUM_PATH")" \
  --dir "$DOWNLOAD_DIR"

DOWNLOADED_DMG="$DOWNLOAD_DIR/$(basename "$DMG_PATH")"
DOWNLOADED_CHECKSUM="$DOWNLOAD_DIR/$(basename "$CHECKSUM_PATH")"
DOWNLOADED_SHA256="$(shasum -a 256 "$DOWNLOADED_DMG" | awk '{print $1}')"
if [[ "$DOWNLOADED_SHA256" != "$LOCAL_SHA256" ]]; then
  echo "Downloaded artifact digest does not match the locally verified DMG." >&2
  exit 1
fi
(
  cd "$DOWNLOAD_DIR"
  shasum -a 256 -c "$(basename "$DOWNLOADED_CHECKSUM")"
)

"$ROOT_DIR/script/verify_release.sh" "$VERSION" "$DOWNLOADED_DMG"

echo "Published and independently verified: $REPOSITORY $TAG"
