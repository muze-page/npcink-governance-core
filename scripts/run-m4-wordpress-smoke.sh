#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOLKIT_ROOT="${NPCINK_ABILITIES_TOOLKIT_PATH:-$(dirname "$ROOT_DIR")/npcink-abilities-toolkit}"
M4_HOST="${NPCINK_CORE_M4_HOST:-muze@172.16.3.35}"
REMOTE_WORKSPACE_ROOT="${NPCINK_CORE_M4_WORKSPACE_ROOT:-/Users/muze/docker-workspaces}"
OUTPUT_PATH="${NPCINK_CORE_WORDPRESS_SMOKE_OUTPUT:-$ROOT_DIR/dist/m4-wordpress-smoke-evidence.json}"

for command_name in git jq scp ssh shasum tar; do
	if ! command -v "$command_name" >/dev/null 2>&1; then
		echo "Missing required command: $command_name" >&2
		exit 127
	fi
done

if [[ -n "$(git -C "$ROOT_DIR" status --porcelain)" ]]; then
	echo "M4 compatibility smoke requires a clean Core worktree." >&2
	exit 1
fi

if [[ ! -d "$TOOLKIT_ROOT/.git" || -n "$(git -C "$TOOLKIT_ROOT" status --porcelain)" ]]; then
	echo "M4 compatibility smoke requires a clean Toolkit checkout." >&2
	exit 1
fi

source_revision="$(git -C "$ROOT_DIR" rev-parse HEAD)"
toolkit_revision="$(git -C "$TOOLKIT_ROOT" rev-parse HEAD)"
short_revision="${source_revision:0:12}"
local_tmp="$(mktemp -d "${TMPDIR:-/tmp}/npcink-core-m4.XXXXXX")"
core_archive="$local_tmp/core-source.tar"
toolkit_archive="$local_tmp/toolkit-source.tar"
package_copy="$local_tmp/npcink-governance-core.zip"
minimum_log="$local_tmp/minimum-profile.log"
current_log="$local_tmp/current-profile.log"
remote_dir=''
minimum_project="npcink_core_69_$short_revision"
current_project="npcink_core_70_$short_revision"

cleanup() {
	if [[ -n "$remote_dir" ]]; then
		ssh "$M4_HOST" "if test -f '$remote_dir/toolkit/docker-compose.official-stack.yml'; then cd '$remote_dir/toolkit'; COMPOSE_PROJECT_NAME='$minimum_project' OFFICIAL_STACK_HTTP_PORT=8931 docker compose -f docker-compose.official-stack.yml down -v --remove-orphans >/dev/null 2>&1 || true; COMPOSE_PROJECT_NAME='$current_project' OFFICIAL_STACK_HTTP_PORT=8932 docker compose -f docker-compose.official-stack.yml down -v --remove-orphans >/dev/null 2>&1 || true; fi; case '$remote_dir' in '$REMOTE_WORKSPACE_ROOT'/npcink-core-release.*) rm -rf -- '$remote_dir' ;; *) exit 2 ;; esac" >/dev/null 2>&1 || true
	fi
	rm -rf "$local_tmp"
}
trap cleanup EXIT

git -C "$ROOT_DIR" archive --format=tar HEAD > "$core_archive"
git -C "$TOOLKIT_ROOT" archive --format=tar HEAD > "$toolkit_archive"
source_archive_sha256="$(shasum -a 256 "$core_archive" | awk '{print $1}')"
toolkit_archive_sha256="$(shasum -a 256 "$toolkit_archive" | awk '{print $1}')"

bash "$ROOT_DIR/scripts/build-release-package.sh" >/dev/null
cp "$ROOT_DIR/build/npcink-governance-core.zip" "$package_copy"
package_sha256="$(shasum -a 256 "$package_copy" | awk '{print $1}')"

remote_dir="$(ssh "$M4_HOST" "mkdir -p '$REMOTE_WORKSPACE_ROOT' && mktemp -d '$REMOTE_WORKSPACE_ROOT/npcink-core-release.XXXXXX'")"
if [[ "$remote_dir" != "$REMOTE_WORKSPACE_ROOT"/npcink-core-release.* ]]; then
	echo "M4 returned an unexpected workspace path: $remote_dir" >&2
	exit 1
fi

scp -q "$core_archive" "$toolkit_archive" "$package_copy" "$M4_HOST:$remote_dir/"
ssh "$M4_HOST" "mkdir -p '$remote_dir/core' '$remote_dir/toolkit' && tar -xf '$remote_dir/core-source.tar' -C '$remote_dir/core' && tar -xf '$remote_dir/toolkit-source.tar' -C '$remote_dir/toolkit' && test \"\$(shasum -a 256 '$remote_dir/npcink-governance-core.zip' | awk '{print \$1}')\" = '$package_sha256'"
docker_version="$(ssh "$M4_HOST" 'docker version --format "{{.Server.Version}}"')"

if ! ssh "$M4_HOST" "cd '$remote_dir/core' && NPCINK_CORE_M4_TOOLKIT_ROOT='$remote_dir/toolkit' NPCINK_CORE_M4_PACKAGE='$remote_dir/npcink-governance-core.zip' NPCINK_CORE_M4_PROJECT_NAME='$minimum_project' NPCINK_CORE_M4_HTTP_PORT=8931 bash scripts/m4-wordpress-package-profile.sh" > "$minimum_log" 2>&1; then
	sed -n '1,4000p' "$minimum_log" >&2
	exit 1
fi
minimum_output="$(<"$minimum_log")"
printf '%s\n' "$minimum_output"
minimum_assertions="$(printf '%s\n' "$minimum_output" | sed -nE 's/^Smoke OK: ([0-9]+) assertions$/\1/p' | tail -n 1)"

if ! ssh "$M4_HOST" "cd '$remote_dir/core' && NPCINK_CORE_M4_TOOLKIT_ROOT='$remote_dir/toolkit' NPCINK_CORE_M4_PACKAGE='$remote_dir/npcink-governance-core.zip' NPCINK_CORE_M4_PROJECT_NAME='$current_project' NPCINK_CORE_M4_HTTP_PORT=8932 NPCINK_CORE_M4_WORDPRESS_VERSION=7.0 NPCINK_CORE_M4_PHP_VERSION=8.5 NPCINK_CORE_M4_SMOKE_LABEL=Current bash scripts/m4-wordpress-package-profile.sh" > "$current_log" 2>&1; then
	sed -n '1,4000p' "$current_log" >&2
	exit 1
fi
current_output="$(<"$current_log")"
printf '%s\n' "$current_output"
current_assertions="$(printf '%s\n' "$current_output" | sed -nE 's/^Smoke OK: ([0-9]+) assertions$/\1/p' | tail -n 1)"

if [[ ! "$minimum_assertions" =~ ^[1-9][0-9]*$ || ! "$current_assertions" =~ ^[1-9][0-9]*$ ]]; then
	echo "M4 smoke output did not contain both assertion totals." >&2
	exit 1
fi

mkdir -p "$(dirname "$OUTPUT_PATH")"
jq -n \
	--arg source_revision "$source_revision" \
	--arg source_archive_sha256 "$source_archive_sha256" \
	--arg package_sha256 "$package_sha256" \
	--arg toolkit_revision "$toolkit_revision" \
	--arg toolkit_archive_sha256 "$toolkit_archive_sha256" \
	--arg docker_server_version "$docker_version" \
	--arg generated_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
	--argjson minimum_assertions "$minimum_assertions" \
	--argjson current_assertions "$current_assertions" \
	'{
		schema_version: "npcink_core_wordpress_smoke_evidence.v1",
		runner: "m4-docker",
		source_revision: $source_revision,
		source_archive_sha256: $source_archive_sha256,
		package_sha256: $package_sha256,
		toolkit_revision: $toolkit_revision,
		toolkit_archive_sha256: $toolkit_archive_sha256,
		docker_server_version: $docker_server_version,
		generated_at: $generated_at,
		profiles: {
			"wordpress-6.9.4-php-8.0": {wordpress: "6.9.4", php: "8.0", assertions: $minimum_assertions, installed_from_zip: true, status: "passed"},
			"wordpress-7.0-php-8.5": {wordpress: "7.0", php: "8.5", assertions: $current_assertions, installed_from_zip: true, status: "passed"}
		}
	}' > "$OUTPUT_PATH"

NPCINK_ABILITIES_TOOLKIT_PATH="$TOOLKIT_ROOT" php "$ROOT_DIR/scripts/check-wordpress-smoke-evidence.php" "$OUTPUT_PATH"
echo "M4 Core WordPress smoke evidence ready: $OUTPUT_PATH"
