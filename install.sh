#!/usr/bin/env bash
# Installs tools and symlinks configs from this repo into your home directory.
# Works two ways:
#   - On a fresh Mac (no git, no Homebrew, no clone) via curl:
#       /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/lbosse/shell-setup/main/install.sh)"
#     The script will install Homebrew + git, clone the repo, and re-exec
#     itself from the cloned copy.
#   - From an existing clone:
#       bash ~/code/shell-setup/install.sh
# Safe to re-run — existing files are backed up, every install is guarded.
set -e

REPO_URL="https://github.com/lbosse/shell-setup.git"
REPO_DIR="$HOME/code/shell-setup"

# Resolve the directory this script is running from. Empty when the script is
# piped via stdin (e.g. curl ... | bash), which is how we detect cold-start.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-}")" 2>/dev/null && pwd)" || SCRIPT_DIR=""

echo ""
echo "==> Installing Homebrew"
# Homebrew — package manager for macOS. Its installer also bootstraps the
# Xcode Command Line Tools (which provide compilers, headers, and a working git).
# Run unconditionally before anything else: both the cold-start clone path and
# the main install path need brew available.
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

# If we're not running from inside a clone (e.g. piped from curl), clone the
# repo now that git is available, then hand off to the on-disk copy.
if [ -z "$SCRIPT_DIR" ] || [ ! -f "$SCRIPT_DIR/zsh/zshrc" ]; then
  echo ""
  echo "==> Cold-start: cloning the repo"
  if [ ! -d "$REPO_DIR" ]; then
    echo "  Cloning shell-setup to $REPO_DIR..."
    mkdir -p "$(dirname "$REPO_DIR")"
    git clone "$REPO_URL" "$REPO_DIR"
  fi
  exec bash "$REPO_DIR/install.sh"
fi

REPO="$SCRIPT_DIR"

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
# Docker Desktop — provides the docker / docker compose / buildx CLIs plus the
# daemon. Installed as a cask (.app in /Applications). Free for personal use;
# check Docker's pricing if running this on a work machine. On first install we
# launch the app so the user can accept the license and start the daemon.
if ! brew list --cask docker &>/dev/null; then
  echo "  Installing Docker Desktop..."
  brew install --cask docker
  echo "  Launching Docker Desktop so you can accept the license..."
  open -a Docker
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
echo "==> Linking zellij config"
mkdir -p "$HOME/.config/zellij"
link "$REPO/zellij/config.kdl" "$HOME/.config/zellij/config.kdl"

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
