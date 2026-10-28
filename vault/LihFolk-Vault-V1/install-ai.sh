#!/usr/bin/env bash
# Installs the vault's ten Roblox AI skills for Claude Code, pointed at this vault (macOS / Linux).
#   bash install-ai.sh            install the skills
#   bash install-ai.sh --global   also add a short always-on note to ~/.claude/CLAUDE.md
set -euo pipefail
VAULT="$(cd "$(dirname "$0")" && pwd)"
SRC="$VAULT/31 AI Skills for Roblox/skills"
DST="$HOME/.claude/skills"
mkdir -p "$DST"
for dir in "$SRC"/*/; do
  name="$(basename "$dir")"
  rm -rf "$DST/$name"; cp -R "$dir" "$DST/$name"
  find "$DST/$name" -name '*.md' -print0 | while IFS= read -r -d '' f; do
    sed -i.bak "s#{{VAULT}}#$VAULT#g" "$f" && rm -f "$f.bak"
  done
  echo "installed skill: $name"
done
if [ "${1:-}" = "--global" ]; then
  MD="$HOME/.claude/CLAUDE.md"; touch "$MD"
  if ! grep -q "<!-- roblox-vault -->" "$MD"; then
    printf '\n<!-- roblox-vault -->\n# Roblox knowledge vault\nA Roblox game-development knowledge vault is at `%s`. For any Roblox task (Luau, Studio, remotes, DataStores, UI, physics, VFX, monetization, assets), first grep `%s/VAULT_INDEX.md` and apply the matching notes, without waiting to be asked. See `%s/AGENTS.md`.\n<!-- /roblox-vault -->\n' "$VAULT" "$VAULT" "$VAULT" >> "$MD"
    echo "added the vault note to $MD"
  fi
fi
echo
echo "Done. Add to your shell profile if you like:  export ROBLOX_VAULT=\"$VAULT\""
echo "Other AI tools: add to your project's AGENTS.md:  For Roblox work, grep $VAULT/VAULT_INDEX.md first and follow $VAULT/AGENTS.md."
