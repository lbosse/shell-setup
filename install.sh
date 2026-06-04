#!/usr/bin/env bash
# Installs tools and symlinks configs from this repo into your home directory.
# Works on macOS (Homebrew) and on Linux / WSL2 (apt + upstream installers).
# Two ways to run:
#   - On a fresh machine (no git, no clone) via curl:
#       /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/lbosse/shell-setup/main/install.sh)"
#     On macOS the script installs Homebrew + git; on Linux it installs git via
#     apt. Either way it then clones the repo and re-execs from the cloned copy.
#   - From an existing clone:
#       bash ~/code/shell-setup/install.sh
# Safe to re-run — existing files are backed up, every install is guarded.
set -e

REPO_URL="https://github.com/lbosse/shell-setup.git"
REPO_DIR="$HOME/code/shell-setup"

# Resolve the directory this script is running from. Empty when the script is
# piped via stdin (e.g. curl ... | bash), which is how we detect cold-start.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-}")" 2>/dev/null && pwd)" || SCRIPT_DIR=""

# Detect platform. The tool-install strategy differs sharply between macOS
# (Homebrew) and Linux (apt + upstream installers); IS_WSL lets us special-case
# Windows Subsystem for Linux where it matters (e.g. Docker).
OS="$(uname -s)"
IS_WSL=false
if [ "$OS" = "Linux" ] && grep -qiE 'microsoft|wsl' /proc/version 2>/dev/null; then
  IS_WSL=true
fi

# Do NOT run this as root. On Linux the script installs into your home directory
# (oh-my-zsh, nvm, config symlinks, ~/.secrets) and escalates with sudo only for
# the specific apt steps. Running the whole thing under sudo makes HOME=/root, so
# everything lands in root's home and your shell is never configured.
if [ "$OS" != "Darwin" ] && [ "$(id -u)" -eq 0 ]; then
  echo "Error: don't run this script with sudo or as root." >&2
  echo "It installs into your home directory and calls sudo itself where needed." >&2
  echo "Re-run as your normal user:  bash ~/code/shell-setup/install.sh" >&2
  exit 1
fi

# Run `apt-get update` at most once, lazily, before the first apt install.
APT_UPDATED=false
apt_install() {
  if ! $APT_UPDATED; then
    echo "  Updating apt package lists (you may be prompted for your sudo password)..."
    sudo apt-get update -y
    APT_UPDATED=true
  fi
  sudo apt-get install -y "$@"
}

if [ "$OS" = "Darwin" ]; then
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
fi

echo ""
echo "==> Ensuring git is available"
# Use whatever git is already on PATH (Xcode CLT, manual install, brew, apt, etc.).
# Only fall back to installing git if it's missing entirely.
if ! command -v git &>/dev/null; then
  if [ "$OS" = "Darwin" ]; then
    brew install git
  else
    apt_install git
  fi
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

if [ "$OS" = "Darwin" ]; then
  echo ""
  echo "==> Checking prerequisites (macOS)"
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
  # Install Node.js LTS via nvm. nvm is a shell function so it must be sourced
  # before it can be called from this script.
  export NVM_DIR="$HOME/.nvm"
  \. "$(brew --prefix)/opt/nvm/nvm.sh"
  if ! nvm ls 'lts/*' --no-colors 2>/dev/null | grep -qv 'N/A'; then
    echo "  Installing Node.js LTS via nvm..."
    nvm install --lts
    nvm use --lts
  else
    echo "  Node.js LTS already installed via nvm — skipping."
  fi
  # jenv — manages multiple Java versions and exposes the active one via JAVA_HOME.
  if ! command -v jenv &>/dev/null; then
    echo "  Installing jenv (Java version manager)..."
    brew install jenv
  fi
  # awscli — official AWS command-line interface for managing AWS services.
  if ! command -v aws &>/dev/null; then
    echo "  Installing AWS CLI..."
    brew install awscli
  fi
  # google-cloud-sdk — gcloud CLI plus bundled tools (gsutil, bq, etc.).
  # Installed as a cask so it uses Google's versioned tarball rather than
  # a community-maintained formula.
  if ! brew list --cask google-cloud-sdk &>/dev/null; then
    echo "  Installing Google Cloud SDK..."
    brew install --cask google-cloud-sdk
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
else
  echo ""
  echo "==> Checking prerequisites (Linux/WSL)"

  # Batch everything that apt provides into a single install. fd ships as
  # `fd-find` on Debian/Ubuntu (binary: fdfind); build-essential gives the C
  # compiler that nvim-treesitter needs to build parsers.
  APT_PKGS=()
  command -v nvim  &>/dev/null || APT_PKGS+=(neovim)
  command -v rg    &>/dev/null || APT_PKGS+=(ripgrep)
  command -v jq    &>/dev/null || APT_PKGS+=(jq)
  command -v gh    &>/dev/null || APT_PKGS+=(gh)
  command -v zsh   &>/dev/null || APT_PKGS+=(zsh)
  command -v unzip &>/dev/null || APT_PKGS+=(unzip)
  command -v curl  &>/dev/null || APT_PKGS+=(curl)
  if ! command -v fd &>/dev/null && ! command -v fdfind &>/dev/null; then
    APT_PKGS+=(fd-find)
  fi
  dpkg -s build-essential &>/dev/null || APT_PKGS+=(build-essential)
  if [ ${#APT_PKGS[@]} -gt 0 ]; then
    echo "  Installing via apt: ${APT_PKGS[*]}"
    apt_install "${APT_PKGS[@]}"
  else
    echo "  All apt-provided tools already present — skipping."
  fi

  # Most upstream installers below drop binaries into ~/.local/bin; make sure it
  # exists. (It's already on PATH via zprofile.)
  mkdir -p "$HOME/.local/bin"

  # Debian/Ubuntu ship fd as `fdfind`; expose it under the conventional `fd`
  # name that Telescope and muscle memory expect.
  if ! command -v fd &>/dev/null && command -v fdfind &>/dev/null; then
    ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
    echo "  Linked fd → fdfind in ~/.local/bin"
  fi

  # nvm — no apt/brew package on Linux; use the upstream install script.
  export NVM_DIR="$HOME/.nvm"
  if [ ! -s "$NVM_DIR/nvm.sh" ]; then
    echo "  Installing nvm (Node version manager)..."
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
  fi
  \. "$NVM_DIR/nvm.sh"
  if ! nvm ls 'lts/*' --no-colors 2>/dev/null | grep -qv 'N/A'; then
    echo "  Installing Node.js LTS via nvm..."
    nvm install --lts
    nvm use --lts
  else
    echo "  Node.js LTS already installed via nvm — skipping."
  fi

  # jenv — no apt package; install from git (the upstream-recommended method).
  # Add ~/.jenv/bin to PATH in your shell rc to use it (zshrc runs `jenv init`).
  if ! command -v jenv &>/dev/null && [ ! -d "$HOME/.jenv" ]; then
    echo "  Installing jenv (Java version manager)..."
    git clone --depth 1 https://github.com/jenv/jenv.git "$HOME/.jenv"
  fi

  # AWS CLI v2 — official bundled installer (apt only ships the legacy v1).
  # Install under ~/.local so we don't need sudo for this step.
  if ! command -v aws &>/dev/null; then
    echo "  Installing AWS CLI v2..."
    awstmp="$(mktemp -d)"
    curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-$(uname -m).zip" -o "$awstmp/awscliv2.zip"
    unzip -q "$awstmp/awscliv2.zip" -d "$awstmp"
    "$awstmp/aws/install" --bin-dir "$HOME/.local/bin" --install-dir "$HOME/.local/aws-cli" --update
    rm -rf "$awstmp"
  fi

  # Google Cloud SDK — official install script drops it in $HOME (no sudo).
  if ! command -v gcloud &>/dev/null && [ ! -d "$HOME/google-cloud-sdk" ]; then
    echo "  Installing Google Cloud SDK..."
    curl -fsSL https://sdk.cloud.google.com | bash -s -- --disable-prompts --install-dir="$HOME"
  fi

  # zellij — terminal multiplexer; pull the latest static musl release binary.
  if ! command -v zellij &>/dev/null; then
    echo "  Installing zellij (terminal multiplexer)..."
    zjtmp="$(mktemp -d)"
    curl -fsSL "https://github.com/zellij-org/zellij/releases/latest/download/zellij-$(uname -m)-unknown-linux-musl.tar.gz" -o "$zjtmp/zellij.tar.gz"
    tar -xzf "$zjtmp/zellij.tar.gz" -C "$HOME/.local/bin"
    rm -rf "$zjtmp"
  fi

  # Docker — on WSL2 the supported path is Docker Desktop for Windows with WSL
  # integration enabled, which exposes the docker CLI inside this distro without
  # running a daemon here. We don't install the Linux engine (it needs
  # systemd/daemon management Docker Desktop handles for you).
  if ! command -v docker &>/dev/null; then
    if $IS_WSL; then
      echo "  Docker not found. On WSL2, install Docker Desktop for Windows and enable"
      echo "  WSL integration for this distro: https://docs.docker.com/desktop/wsl/"
    else
      echo "  Docker not found. Install Docker Engine for your distro:"
      echo "  https://docs.docker.com/engine/install/"
    fi
  fi
fi

# Claude Code — Anthropic's official CLI agent for coding tasks. Cross-platform
# upstream installer (drops a binary into ~/.local/bin).
if ! command -v claude &>/dev/null; then
  echo "  Installing Claude Code (Anthropic CLI agent)..."
  curl -fsSL https://claude.ai/install.sh | bash
fi

echo ""
echo "==> Installing Oh My Zsh"
# oh-my-zsh — framework for managing zsh configuration (themes, plugins, helpers).
# --unattended: skip the "change default shell" prompt.
# --keep-zshrc: don't overwrite the .zshrc we're about to symlink.
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "  Installing Oh My Zsh..."
  RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" \
    --keep-zshrc
else
  echo "  Oh My Zsh already installed — skipping."
fi

# Make zsh the default login shell. macOS already ships zsh as the default, so
# this only matters on Linux/WSL (where the default is usually bash). chsh edits
# /etc/passwd and will prompt for your password.
if [ "$OS" != "Darwin" ]; then
  echo ""
  echo "==> Default shell"
  ZSH_PATH="$(command -v zsh || true)"
  CURRENT_SHELL="$(getent passwd "$USER" 2>/dev/null | cut -d: -f7)"
  if [ -z "$ZSH_PATH" ]; then
    echo "  zsh not found — skipping (install it and run 'chsh -s \$(which zsh)')."
  elif [ "$CURRENT_SHELL" = "$ZSH_PATH" ]; then
    echo "  Login shell already zsh — skipping."
  else
    # chsh requires the target shell to be listed in /etc/shells.
    if ! grep -qxF "$ZSH_PATH" /etc/shells 2>/dev/null; then
      echo "  Adding $ZSH_PATH to /etc/shells..."
      echo "$ZSH_PATH" | sudo tee -a /etc/shells >/dev/null
    fi
    echo "  Setting zsh as your login shell (you may be prompted for your password)..."
    if chsh -s "$ZSH_PATH"; then
      if $IS_WSL; then
        echo "  Done. On WSL2 the change won't apply until you fully restart the distro:"
        echo "  run 'wsl --shutdown' from Windows (PowerShell/CMD), then reopen WSL."
      else
        echo "  Done. Log out and back in for the change to take effect."
      fi
    else
      echo "  chsh failed — set it manually later with: chsh -s \"$ZSH_PATH\""
    fi
  fi
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
