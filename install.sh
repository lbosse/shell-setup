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
echo "==> Installing Homebrew"
# Homebrew — package manager for macOS. Its installer also bootstraps the
# Xcode Command Line Tools (which provide a working git, compilers, headers).
if ! command -v brew &>/dev/null; then
  echo "  Installing Homebrew (accept the Xcode CLT GUI prompt if it appears)..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Make brew available in the rest of this script.
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

echo ""
echo "==> Installing git via Homebrew"
# git ships with the Xcode CLT, but that copy lags behind upstream. Install
# the brew formula so we get current git on PATH (homebrew/bin precedes /usr/bin).
if ! brew list git &>/dev/null; then
  brew install git
fi

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
# gh — GitHub's official CLI. Used for PR/issue/release workflows from the terminal.
if ! command -v gh &>/dev/null; then
  echo "  Installing gh (GitHub CLI)..."
  brew install gh
fi
# fd — modern, faster, more ergonomic alternative to find(1).
if ! command -v fd &>/dev/null; then
  echo "  Installing fd (modern find replacement)..."
  brew install fd
fi
# jq — command-line JSON processor and query tool.
if ! command -v jq &>/dev/null; then
  echo "  Installing jq (JSON processor)..."
  brew install jq
fi
# nvm — Node version manager. Sourced from $(brew --prefix)/opt/nvm in zshrc.
if ! brew list nvm &>/dev/null; then
  echo "  Installing nvm (Node version manager)..."
  brew install nvm
fi
# jenv — manages multiple Java versions and exposes the active one via JAVA_HOME.
if ! command -v jenv &>/dev/null; then
  echo "  Installing jenv (Java version manager)..."
  brew install jenv
fi
# zellij — terminal multiplexer (tmux-like) with a friendlier default UX.
if ! command -v zellij &>/dev/null; then
  echo "  Installing zellij (terminal multiplexer)..."
  brew install zellij
fi
# Claude Code — Anthropic's official CLI agent for coding tasks.
if ! command -v claude &>/dev/null; then
  echo "  Installing Claude Code (Anthropic CLI agent)..."
  curl -fsSL https://claude.ai/install.sh | bash
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
