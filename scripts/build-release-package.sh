#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLUGIN_SLUG="npcink-governance-core"
BUILD_DIR="$ROOT_DIR/build"
PACKAGE_DIR="$BUILD_DIR/$PLUGIN_SLUG"
ZIP_FILE="$BUILD_DIR/$PLUGIN_SLUG.zip"

for command_name in rsync zip; do
	if ! command -v "$command_name" >/dev/null 2>&1; then
		echo "Missing required command: $command_name" >&2
		exit 2
	fi
done

rm -rf "$BUILD_DIR"
mkdir -p "$PACKAGE_DIR"
rsync -a --delete --exclude-from="$ROOT_DIR/.distignore" "$ROOT_DIR/" "$PACKAGE_DIR/"

# ZIP stores local timestamps and optional host metadata. Normalize both so
# the same release contents produce the same archive on repeated builds.
export TZ=UTC
find "$PACKAGE_DIR" ! -type l -exec touch -t 200001010000 {} +
find "$PACKAGE_DIR" -type l -exec touch -h -t 200001010000 {} +

(
	cd "$BUILD_DIR"
	find "$PLUGIN_SLUG" -print | LC_ALL=C sort | zip -Xq "$ZIP_FILE" -@
)

echo "$ZIP_FILE"
