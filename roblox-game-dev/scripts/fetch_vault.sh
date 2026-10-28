#!/usr/bin/env bash
# Fetch a note/folder of the LihFolk Vault V1 (CC BY 4.0, by LihFolk) from GitHub via sparse clone.
# Usage: fetch_vault.sh <path-inside-vault> [dest]
#   fetch_vault.sh "04 Data and Persistence/Session Locking and Profile Libraries.md"
#   fetch_vault.sh "22 Anti-Exploit and Security" ./vault-cache
# Re-running with another path adds it to the same clone. Prints the local path.
set -euo pipefail

REPO_URL="${VAULT_REPO_URL:-https://github.com/evdokimovbusinez-code/roblox-game-dev.git}"
VAULT_DIR="vault/LihFolk-Vault-V1"

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ] || [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  echo "Usage: $(basename "$0") <path-inside-vault> [dest]" >&2
  echo "  path-inside-vault: file or folder relative to the vault root, e.g. \"22 Anti-Exploit and Security\"" >&2
  echo "  dest: clone directory (default ./vault-cache)" >&2
  exit 2
fi

REL="${1#/}"
REL="${REL%/}"
DEST="${2:-./vault-cache}"

case "/$REL/" in
  */../*) echo "error: '..' is not allowed in path" >&2; exit 2 ;;
esac
if [ -z "$REL" ]; then echo "error: empty path" >&2; exit 2; fi

TARGET="$VAULT_DIR/$REL"

if [ ! -d "$DEST/.git" ]; then
  mkdir -p "$DEST"
  git clone --depth 1 --filter=blob:none --sparse --no-checkout "$REPO_URL" "$DEST" >&2
  git -C "$DEST" sparse-checkout init --no-cone >&2
fi

# Non-cone mode takes literal paths; anchor with a leading slash. Add to existing list.
git -C "$DEST" sparse-checkout add --no-cone "/$TARGET" >&2 2>/dev/null \
  || git -C "$DEST" sparse-checkout set --no-cone "/$TARGET" >&2
git -C "$DEST" checkout >&2

if [ -e "$DEST/$TARGET" ]; then
  echo "$DEST/$TARGET"
else
  echo "error: '$REL' not found in $VAULT_DIR (check spelling, quotes, and that the vault is pushed)" >&2
  exit 1
fi
