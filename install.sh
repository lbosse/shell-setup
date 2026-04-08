#!/usr/bin/env bash
# Sets up symlinks from this repo into your home directory.
# Run this after cloning the repo or when adding a new machine.
# Safe to re-run — existing files are backed up, not deleted.
set -e

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

link() {
  local src="$1"
  local dst="$2"
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    echo "  Backing up $dst → $dst.bak"
    mv "$dst" "$dst.bak"
  fi
  ln -sf "$src" "$dst"
  echo "  Linked: $dst"
}

echo ""
echo "==> Checking prerequisites"
if ! command -v nvim &>/dev/null; then
  echo "  Installing neovim..."
  brew install neovim
fi
if ! command -v rg &>/dev/null; then
  echo "  Installing ripgrep (needed for Telescope live grep)..."
  brew install ripgrep
fi

echo ""
echo "==> Linking zsh config"
link "$REPO/zsh/zshrc"    "$HOME/.zshrc"
link "$REPO/zsh/zprofile" "$HOME/.zprofile"

echo ""
echo "==> Linking neovim config"
mkdir -p "$HOME/.config/nvim"
link "$REPO/nvim/init.lua" "$HOME/.config/nvim/init.lua"

echo ""
echo "==> Linking ghostty config"
mkdir -p "$HOME/.config/ghostty"
link "$REPO/ghostty/config" "$HOME/.config/ghostty/config"

echo ""
echo "==> Secrets"
if [ ! -f "$HOME/.secrets" ]; then
  cp "$REPO/secrets.example" "$HOME/.secrets"
  chmod 600 "$HOME/.secrets"
  echo "  Created ~/.secrets from template — fill in your tokens."
else
  echo "  ~/.secrets already exists — skipping."
fi

echo ""
echo "==> Installing neovim plugins"
nvim --headless -c 'lua require("lazy").sync({ show = false, wait = true })' -c 'quitall'

echo ""
echo "Done. Open a new terminal window to reload .zprofile and .zshrc."
