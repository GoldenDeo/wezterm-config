#!/usr/bin/env bash
set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP="$HOME/.wezterm.lua"
CONFIG_LINK="$HOME/.config/wezterm"

echo "Setting up WezTerm config..."
echo "  repo: $REPO_DIR"

# ~/.config/wezterm symlink
if [ -d "$CONFIG_LINK" ] && [ ! -L "$CONFIG_LINK" ]; then
  mv "$CONFIG_LINK" "${CONFIG_LINK}.backup.$(date +%Y%m%d_%H%M%S)"
fi
[ -L "$CONFIG_LINK" ] && rm "$CONFIG_LINK"
mkdir -p "$HOME/.config"
ln -s "$REPO_DIR" "$CONFIG_LINK"
echo "  linked: ~/.config/wezterm → $REPO_DIR"

echo "Done!"
