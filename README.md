# shell-setup

Personal shell configuration for macOS (zsh + neovim + ghostty).

## Prerequisites

- A terminal emulator of your choice. A `ghostty` config ships with this repo,
  but any emulator (Terminal.app, iTerm2, Alacritty, etc.) will work.
- Everything else (Homebrew, git, the tools listed below) is installed by the
  scripts — a stock macOS install is enough to get started.

> **A note for the dark-theme crowd:** this setup is unapologetically
> light-themed (ghostty: selenized-light, zellij: solarized-light, et al.).
> Maybe grab some sunglasses before you fire it up ☀️🕶️

## Structure

```
shell-setup/
├── zsh/
│   ├── zshrc       → ~/.zshrc
│   └── zprofile    → ~/.zprofile
├── nvim/
│   └── init.lua    → ~/.config/nvim/init.lua
├── ghostty/
│   └── config      → ~/.config/ghostty/config
├── zellij/
│   └── config.kdl  → ~/.config/zellij/config.kdl
├── secrets.example → template for ~/.secrets (never committed)
└── install.sh      → installs tools and sets up all symlinks
                      (also self-bootstraps brew + git + clone on a fresh Mac)
```

## First-time setup

### Fresh machine (no git, no Homebrew)

Paste this into your terminal — `install.sh` will install Homebrew (which pulls
in the Xcode Command Line Tools and git), clone this repo to
`~/code/shell-setup`, and then re-exec itself to finish the install:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/lbosse/shell-setup/main/install.sh)"
```

### Already have git / repo cloned

```bash
# 1. Run the install script
bash ~/code/shell-setup/install.sh

# 2. Fill in your API tokens
#    (install.sh creates ~/.secrets from the template if it doesn't exist)
vim ~/.secrets

# 3. Open a new terminal window
# (needed to reload both .zprofile and .zshrc in the correct order)
```

`install.sh` will:
- Install **Homebrew** if not present (its installer also bootstraps the Xcode Command Line Tools, which provide compilers, headers, and a working git)
- Install the following via Homebrew if not present:
  - **git** — the Homebrew formula, which stays newer than the CLT-bundled copy
  - **neovim** — text editor
  - **ripgrep** — fast recursive grep, used by Telescope's live grep
  - **gh** — GitHub CLI (PRs, issues, releases from the terminal)
  - **fd** — modern, faster `find` replacement
  - **jq** — command-line JSON processor
  - **nvm** — Node version manager (sourced from `/opt/homebrew/opt/nvm` in `.zshrc`)
  - **jenv** — Java version manager (switches `JAVA_HOME` per shell/project)
  - **zellij** — terminal multiplexer (tmux-style sessions, panes, tabs)
  - **Docker Desktop** (Homebrew cask) — installs the `docker`/`docker compose`/`buildx` CLIs and the daemon; on first install the script launches the app so you can accept the license
- Install **Claude Code** (Anthropic's official CLI agent) via the upstream installer if not present
- Symlink each config file to its correct home directory location
- Back up any existing files it would overwrite (as `*.bak`)
- Create `~/.secrets` from `secrets.example` if it doesn't exist

## Secrets

API tokens and credentials live in `~/.secrets`, which is **not tracked in git**.
See `secrets.example` for the expected variables. After editing, reload with `source ~/.secrets`.

## Neovim

On first launch, neovim will bootstrap `lazy.nvim` and download all plugins automatically.
Language servers (Kotlin, Java/jdtls) are installed via Mason on first use — run `:Mason` to check status.

### Key bindings (LSP — active when editing Kotlin/Java)

| Key            | Action                      |
|----------------|-----------------------------|
| `gd`           | Go to definition            |
| `gD`           | Go to declaration           |
| `gi`           | Go to implementation        |
| `K`            | Show documentation (hover)  |
| `gr`           | Find all references         |
| `<leader>rn`   | Rename symbol               |
| `<leader>ca`   | Code action / quick fix     |
| `[d` / `]d`    | Previous / next diagnostic  |

### Telescope (fuzzy finder)

| Key            | Action        |
|----------------|---------------|
| `<leader>ff`   | Find files    |
| `<leader>fg`   | Live grep     |
| `<leader>fb`   | Open buffers  |

## Adding a new machine

For a fresh macOS install, use the curl one-liner from the
[Fresh machine](#fresh-machine-no-git-no-homebrew) section above — `install.sh`
self-bootstraps Homebrew, git, and the clone in one shot. If you already have
git, you can clone manually instead:

```bash
git clone https://github.com/lbosse/shell-setup.git ~/code/shell-setup
bash ~/code/shell-setup/install.sh
# Then open a new terminal window — .zprofile won't reload until a new login shell starts
```
