#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ZIP_FILE="$ROOT_DIR/build/npcink-governance-core.zip"
TIMESTAMP_REFERENCE="$(mktemp)"
UNTRACKED_FIXTURE="$ROOT_DIR/.npcink-release-untracked-fixture"

cleanup() {
	touch -r "$TIMESTAMP_REFERENCE" "$ROOT_DIR/docs"
	rm -f "$TIMESTAMP_REFERENCE"
	rm -f "$UNTRACKED_FIXTURE"
}
trap cleanup EXIT

touch -r "$ROOT_DIR/docs" "$TIMESTAMP_REFERENCE"
touch "$UNTRACKED_FIXTURE"

hash_zip() {
	php -r 'echo hash_file("sha256", $argv[1]);' "$ZIP_FILE"
}

cd "$ROOT_DIR"
bash scripts/build-release-package.sh >/dev/null
first_sha256="$(hash_zip)"

# Excluded source metadata must not leak into the distribution archive.
touch -t 200101010101 docs
bash scripts/build-release-package.sh >/dev/null
second_sha256="$(hash_zip)"

if [[ "$first_sha256" != "$second_sha256" ]]; then
	echo "Release ZIP checksum changed across equivalent builds." >&2
	echo "First:  $first_sha256" >&2
	echo "Second: $second_sha256" >&2
	exit 1
fi

unzip -tq "$ZIP_FILE" >/dev/null

bad_entry="$(unzip -Z1 "$ZIP_FILE" | awk -F/ '$1 != "npcink-governance-core" { print; exit }')"
if [[ -n "$bad_entry" ]]; then
	echo "Package contains an entry outside npcink-governance-core/: $bad_entry" >&2
	exit 1
fi

for forbidden in tests docs scripts stubs vendor .git .github; do
	if unzip -Z1 "$ZIP_FILE" | grep -E "^npcink-governance-core/${forbidden}(/|$)" >/dev/null; then
		echo "Package contains forbidden release path: $forbidden" >&2
		exit 1
	fi
done

if unzip -Z1 "$ZIP_FILE" | grep -F 'npcink-governance-core/.npcink-release-untracked-fixture' >/dev/null; then
	echo "Package contains an untracked workspace file." >&2
	exit 1
fi

echo "Reproducible release package: ok ($second_sha256)"
