#!/usr/bin/env bash
# Static analysis of the whole project with luau-lsp. Run from the template root: scripts/analyze.sh
# Needs: luau-lsp (rokit install). Optional: rojo + wally (preferred); without them a stub sourcemap is generated.
# Env:   GLOBAL_TYPES=path/to/globalTypes.d.luau  (default: downloaded from luau-lsp.pages.dev)
set -euo pipefail
cd "$(dirname "$0")/.."

DEFS="${GLOBAL_TYPES:-globalTypes.d.luau}"
if [ ! -f "$DEFS" ]; then
  curl -sSfL https://luau-lsp.pages.dev/type-definitions/globalTypes.None.d.luau -o "$DEFS"
fi

if command -v rojo >/dev/null 2>&1 && ls ServerPackages/ProfileStore.lua* >/dev/null 2>&1; then
  rojo sourcemap default.project.json --output sourcemap.json
  IGNORE=(--ignore "Packages/**" --ignore "ServerPackages/**")
else
  echo "[analyze] Packages not installed: using analysis/stubs (stub ProfileStore, NOT the real package)"
  python3 scripts/make_sourcemap.py --stubs sourcemap.json
  IGNORE=(--ignore "analysis/**")
fi

luau-lsp analyze --platform roblox --sourcemap sourcemap.json --definitions "@roblox=$DEFS" \
  --base-luaurc .luaurc "${IGNORE[@]}" src analysis
