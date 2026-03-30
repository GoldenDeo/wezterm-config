#!/usr/bin/env bash
set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="$HOME/.wezterm.lua"
SOURCE="$REPO_DIR/wezterm.lua"

echo "Setting up WezTerm config symlink..."
echo "  source: $SOURCE"
echo "  target: $TARGET"

# Backup existing file if it's not already a symlink
if [ -f "$TARGET" ] && [ ! -L "$TARGET" ]; then
  BACKUP="$TARGET.backup.$(date +%Y%m%d_%H%M%S)"
  echo "  backup: $BACKUP"
  mv "$TARGET" "$BACKUP"
fi

# Remove existing symlink if present
[ -L "$TARGET" ] && rm "$TARGET"

ln -s "$SOURCE" "$TARGET"
echo "Done! ~/.wezterm.lua → $SOURCE"
