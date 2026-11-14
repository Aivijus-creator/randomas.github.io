#!/usr/bin/env bash
# Builds ../Monstergarten.rbxlx: runs the real game code in a small Roblox mock (tools/rbxmock) to build the
# lobby, the daycare and the characters, then writes a Roblox place file with rbx_xml (tools/placegen).
# Needs Rust (cargo). Usage: tools/build_place.sh [output.rbxlx]
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
OUT="${1:-$ROOT/../Monstergarten.rbxlx}"
TMP="$(mktemp -d)"
(cd "$HERE/luaurun" && cargo build --release -q)
(cd "$HERE/placegen" && cargo build --release -q)
RUN="$HERE/luaurun/target/release/luaurun"
# syntax check every Luau file
"$RUN" $(find "$ROOT/src" -name "*.lua")
{ echo "MOCK_DIR = \"$HERE/rbxmock\""; echo "PROJECT_ROOT = \"$ROOT\""; echo "OUT_JSON = \"$TMP/place.json\""; cat "$HERE/rbxmock/export.luau"; } > "$TMP/export.luau"
"$RUN" --run "$TMP/export.luau"
"$HERE/placegen/target/release/placegen" "$TMP/place.json" "$OUT"
echo "Place written to $OUT"
