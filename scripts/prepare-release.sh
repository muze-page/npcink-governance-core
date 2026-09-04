#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLUGIN_SLUG="npcink-governance-core"
PLUGIN_FILE="$ROOT_DIR/$PLUGIN_SLUG.php"
README_FILE="$ROOT_DIR/readme.txt"
ZIP_FILE="$ROOT_DIR/build/$PLUGIN_SLUG.zip"

EXPECTED_VERSION="${EXPECTED_VERSION:-}"
ALLOW_DIRTY="${ALLOW_DIRTY:-0}"
SKIP_SMOKE="${SKIP_SMOKE:-0}"

usage() {
	cat <<USAGE
Usage: scripts/prepare-release.sh [--version <version>] [--allow-dirty] [--skip-smoke]

Runs the local WordPress.org release gate, builds build/$PLUGIN_SLUG.zip, and
checks the package root and version metadata.

Options:
  --version <version>  Require plugin header, version constant, and Stable tag to match.
  --allow-dirty       Allow a dirty Git working tree. Intended for local script testing.
  --skip-smoke        Skip composer smoke:wp. Do not use for a real WordPress.org release.
  -h, --help          Show this help.
USAGE
}

while [[ $# -gt 0 ]]; do
	case "$1" in
		--version)
			EXPECTED_VERSION="${2:-}"
			if [[ -z "$EXPECTED_VERSION" ]]; then
				echo "Missing value for --version." >&2
				exit 2
			fi
			shift 2
			;;
		--allow-dirty)
			ALLOW_DIRTY=1
			shift
			;;
		--skip-smoke)
			SKIP_SMOKE=1
			shift
			;;
		-h|--help)
			usage
			exit 0
			;;
		*)
			echo "Unknown argument: $1" >&2
			usage >&2
			exit 2
			;;
	esac
done

require_command() {
	if ! command -v "$1" >/dev/null 2>&1; then
		echo "Missing required command: $1" >&2
		exit 2
	fi
}

read_plugin_header_version() {
	sed -nE 's/^[[:space:]]+\*[[:space:]]Version:[[:space:]]*([^[:space:]]+).*/\1/p' "$PLUGIN_FILE" | head -n 1
}

read_plugin_constant_version() {
	sed -nE "s/^define\\( 'NPCINK_GOVERNANCE_CORE_VERSION', '([^']+)' \\);/\\1/p" "$PLUGIN_FILE" | head -n 1
}

read_stable_tag() {
	sed -nE 's/^Stable tag:[[:space:]]*([^[:space:]]+).*/\1/p' "$README_FILE" | head -n 1
}

require_command composer
require_command git
require_command unzip

cd "$ROOT_DIR"

if [[ "$ALLOW_DIRTY" != "1" && -n "$(git status --short)" ]]; then
	echo "Working tree is not clean. Commit or stash changes before preparing a release." >&2
	echo "Set ALLOW_DIRTY=1 or pass --allow-dirty only for local script testing." >&2
	git status --short >&2
	exit 1
fi

header_version="$(read_plugin_header_version)"
constant_version="$(read_plugin_constant_version)"
stable_tag="$(read_stable_tag)"

if [[ -z "$header_version" || -z "$constant_version" || -z "$stable_tag" ]]; then
	echo "Could not read release version metadata from plugin file and readme.txt." >&2
	exit 1
fi

if [[ "$header_version" != "$constant_version" || "$header_version" != "$stable_tag" ]]; then
	echo "Version mismatch:" >&2
	echo "  Plugin header: $header_version" >&2
	echo "  Version constant: $constant_version" >&2
	echo "  Stable tag: $stable_tag" >&2
	exit 1
fi

if [[ -n "$EXPECTED_VERSION" && "$header_version" != "$EXPECTED_VERSION" ]]; then
	echo "Expected version $EXPECTED_VERSION, found $header_version." >&2
	exit 1
fi

echo "Release version: $header_version"

composer validate --no-check-publish
composer test:all
composer check:wporg

if [[ "$SKIP_SMOKE" == "1" ]]; then
	echo "Skipping composer smoke:wp because --skip-smoke was passed."
else
	composer smoke:wp
fi

composer package:release

if [[ ! -f "$ZIP_FILE" ]]; then
	echo "Expected package was not created: $ZIP_FILE" >&2
	exit 1
fi

bad_entry="$(unzip -Z1 "$ZIP_FILE" | awk -F/ -v root="$PLUGIN_SLUG" '$1 != root { print; exit }')"
if [[ -n "$bad_entry" ]]; then
	echo "Package contains entry outside $PLUGIN_SLUG/: $bad_entry" >&2
	exit 1
fi

if [[ ! -f "$ROOT_DIR/build/$PLUGIN_SLUG/$PLUGIN_SLUG.php" ]]; then
	echo "Package build directory is missing $PLUGIN_SLUG/$PLUGIN_SLUG.php." >&2
	exit 1
fi

# Run the release-only Plugin Check against the exact files that will be shipped.
package_check_root="$(mktemp -d "${TMPDIR:-/tmp}/npcink-governance-core-package.XXXXXX")"
package_check_link="${WP_PATH:-/Users/muze/Local Sites/magick-ai/app/public}/wp-content/plugins/$PLUGIN_SLUG"
package_check_backup="${package_check_link}.release-backup"
cleanup_package_check() {
	rm -rf "$package_check_root"
	if [[ -e "$package_check_backup" || -L "$package_check_backup" ]]; then
		if [[ -e "$package_check_link" || -L "$package_check_link" ]]; then
			rm -f "$package_check_link"
		fi
		mv "$package_check_backup" "$package_check_link"
	fi
}
trap cleanup_package_check EXIT

unzip -q "$ZIP_FILE" -d "$package_check_root"
if [[ -e "$package_check_link" || -L "$package_check_link" ]]; then
	mv "$package_check_link" "$package_check_backup"
fi
PLUGIN_ROOT="$package_check_root/$PLUGIN_SLUG" composer plugin-check:release

echo "Release package ready: $ZIP_FILE"
