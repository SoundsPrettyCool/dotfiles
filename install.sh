#!/bin/bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Claude Code ---
curl -fsSL https://claude.ai/install.sh | bash

# --- VS Code settings ---
# Merge this repo's settings into the remote machine settings so they apply
# in every codespace / dev container. Existing keys are kept; ours win on conflict.
SRC_SETTINGS="$DOTFILES_DIR/.vscode/settings.json"

if [ -d "$HOME/.vscode-remote" ]; then
  MACHINE_DIR="$HOME/.vscode-remote/data/Machine"  # Codespaces / Dev Containers
else
  MACHINE_DIR="$HOME/.vscode-server/data/Machine"  # Remote-SSH
fi
DEST_SETTINGS="$MACHINE_DIR/settings.json"

mkdir -p "$MACHINE_DIR"

if [ ! -s "$DEST_SETTINGS" ]; then
  cp "$SRC_SETTINGS" "$DEST_SETTINGS"
elif command -v jq >/dev/null 2>&1; then
  tmp="$(mktemp)"
  if jq -s '.[0] * .[1]' "$DEST_SETTINGS" "$SRC_SETTINGS" >"$tmp"; then
    mv "$tmp" "$DEST_SETTINGS"
  else
    rm -f "$tmp"
    echo "dotfiles: could not merge $DEST_SETTINGS (not plain JSON?), skipping" >&2
  fi
elif command -v python3 >/dev/null 2>&1; then
  python3 - "$DEST_SETTINGS" "$SRC_SETTINGS" <<'EOF' || echo "dotfiles: could not merge settings, skipping" >&2
import json, sys
dest, src = sys.argv[1], sys.argv[2]
with open(dest) as f:
    merged = json.load(f)
with open(src) as f:
    merged.update(json.load(f))
with open(dest, "w") as f:
    json.dump(merged, f, indent=4)
EOF
else
  echo "dotfiles: need jq or python3 to merge VS Code settings, skipping" >&2
fi
