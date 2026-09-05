#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "usage: $0 MATERIAL_DIRECTORY VERSION" >&2
  exit 2
fi
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MATERIAL_DIR="$1"
VERSION="$2"
for name in LICENSE LICENSE.upstream NOTICE SOURCE.md; do
  if [[ ! -f "$MATERIAL_DIR/$name" ]]; then
    echo "Missing license/source material: $MATERIAL_DIR/$name" >&2
    exit 1
  fi
  if ! cmp -s "$ROOT_DIR/$name" "$MATERIAL_DIR/$name"; then
    echo "License/source material differs from release source: $name" >&2
    exit 1
  fi
done
rg -q '^SPDX-License-Identifier: GPL-3.0-or-later$' "$MATERIAL_DIR/NOTICE"
rg -q 'GNU GENERAL PUBLIC LICENSE' "$MATERIAL_DIR/LICENSE"
rg -q '^MIT License$' "$MATERIAL_DIR/LICENSE.upstream"
rg -F -x -q "https://github.com/r3d42-git/MenuBarIO/tree/v$VERSION" "$MATERIAL_DIR/SOURCE.md"
echo "Verified GPL, upstream notice and exact source reference: $MATERIAL_DIR"
