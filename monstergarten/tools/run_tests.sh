#!/usr/bin/env bash
# Runs the game in the Roblox mock: boot, a solo shift, every UI button, and a full accelerated shift.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
(cd "$HERE/luaurun" && cargo build --release -q)
RUN="$HERE/luaurun/target/release/luaurun"
TMP="$(mktemp -d)"
for t in smoke buttons fullshift; do
	{ echo "MOCK_DIR = \"$HERE/rbxmock\""; echo "PROJECT_ROOT = \"$ROOT\""; cat "$HERE/rbxmock/$t.luau"; } > "$TMP/$t.luau"
	echo "== $t"; "$RUN" --run "$TMP/$t.luau" | grep -E "errors|ERR|buttons pressed|results|stars|lobby" || true
done
