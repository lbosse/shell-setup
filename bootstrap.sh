#!/usr/bin/env bash
# Cold-start installer for a fresh macOS machine that does not yet have
# git or Homebrew. Installs Homebrew (which also bootstraps the Xcode
# Command Line Tools, providing git), clones this repo, and then hands
# off to install.sh.
#
# Run directly from a fresh terminal:
#   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/lbosse/shell-setup/main/bootstrap.sh)"
#
# Safe to re-run; each step is guarded.
set -e

REPO_URL="https://github.com/lbosse/shell-setup.git"
REPO_DIR="$HOME/code/shell-setup"

if ! command -v brew &>/dev/null; then
  echo "==> Installing Homebrew (accept the Xcode CLT GUI prompt if it appears)..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

if ! command -v git &>/dev/null; then
  echo "==> Installing git..."
  brew install git
fi

if [ ! -d "$REPO_DIR" ]; then
  echo "==> Cloning shell-setup to $REPO_DIR..."
  mkdir -p "$(dirname "$REPO_DIR")"
  git clone "$REPO_URL" "$REPO_DIR"
fi

exec bash "$REPO_DIR/install.sh"
