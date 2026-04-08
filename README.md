# shell-setup

Personal shell configuration for macOS (zsh + neovim + ghostty).

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
├── secrets.example → template for ~/.secrets (never committed)
└── install.sh      → sets up all symlinks
```

## First-time setup

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
- Install neovim and ripgrep via Homebrew if not present
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

```bash
git clone <your-repo-url> ~/code/shell-setup
bash ~/code/shell-setup/install.sh
# Then open a new terminal window — .zprofile won't reload until a new login shell starts
```
