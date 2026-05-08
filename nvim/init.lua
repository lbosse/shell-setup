-- =============================================================
-- Options
-- (Equivalent of your .vimrc, plus sensible neovim defaults)
-- =============================================================
vim.opt.ruler = true
vim.opt.number = true
vim.opt.relativenumber = true       -- relative line numbers are great for jumping with e.g. 5j
vim.opt.shortmess:remove("S")       -- show "1/N" match count during search
vim.opt.autoread = true
vim.opt.expandtab = true            -- spaces instead of tabs
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.ignorecase = true
vim.opt.smartcase = true            -- case-sensitive when you type a capital
vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"          -- always show gutter (prevents layout shifting when LSP adds signs)
vim.opt.updatetime = 250            -- faster CursorHold events (used by LSP hover)
vim.opt.scrolloff = 8               -- keep 8 lines visible above/below cursor

-- Re-check file on focus or buffer enter (same as your autocmd)
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter" }, { command = "checktime" })

-- Use the terminal's own background color instead of nvim's theme background
local function clear_background()
  vim.api.nvim_set_hl(0, "Normal",   { bg = "none" })
  vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
end
clear_background()  -- apply immediately on startup
vim.api.nvim_create_autocmd("ColorScheme", { pattern = "*", callback = clear_background })

-- =============================================================
-- Bootstrap lazy.nvim (plugin manager — installs itself on first run)
-- =============================================================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- =============================================================
-- Plugins
-- =============================================================
require("lazy").setup({

  -- ----------------------------------------------------------
  -- Syntax highlighting via Tree-sitter
  -- Much better than regex-based highlighting — understands the AST.
  -- Kotlin and Java parsers give you accurate highlighting and
  -- indentation in Spring Boot code.
  -- ----------------------------------------------------------
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.config").setup({
        ensure_installed = {
          "kotlin", "java",           -- your primary languages
          "python",                   -- Python
          "lua", "bash",              -- config/scripting
          "json", "yaml", "xml",      -- Spring Boot config files
          "markdown", "markdown_inline",
        },
        highlight = { enable = true },
        indent   = { enable = true },
      })
    end,
  },

  -- ----------------------------------------------------------
  -- Mason — installs and manages LSP servers, linters, formatters.
  -- Run :Mason inside neovim to open the UI.
  -- ----------------------------------------------------------
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup()
    end,
  },

  -- Mason-lspconfig: tells Mason which servers to auto-install.
  -- No longer needs nvim-lspconfig as a dependency (mason-lspconfig v2+).
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "kotlin_language_server",   -- Kotlin LSP
          "jdtls",                    -- Java (Eclipse JDT)
          "pyright",                  -- Python type-checking LSP
          "ruff",                     -- Python linter / formatter
        },
        automatic_installation = true,
      })
    end,
  },

  -- ----------------------------------------------------------
  -- Completion (nvim-cmp)
  -- Tab/Shift-Tab to navigate, Enter to confirm.
  -- ----------------------------------------------------------
  { "hrsh7th/cmp-nvim-lsp" },
  { "hrsh7th/cmp-buffer" },
  { "hrsh7th/cmp-path" },
  {
    "hrsh7th/nvim-cmp",
    config = function()
      local cmp = require("cmp")
      cmp.setup({
        mapping = cmp.mapping.preset.insert({
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<CR>"]      = cmp.mapping.confirm({ select = true }),
          ["<Tab>"]     = cmp.mapping.select_next_item(),
          ["<S-Tab>"]   = cmp.mapping.select_prev_item(),
          ["<C-e>"]     = cmp.mapping.abort(),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "buffer" },
          { name = "path" },
        }),
      })
    end,
  },

  -- ----------------------------------------------------------
  -- Telescope — fuzzy finder for files, grep, buffers, etc.
  -- Requires ripgrep for live_grep: brew install ripgrep
  -- ----------------------------------------------------------
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local builtin = require("telescope.builtin")
      vim.keymap.set("n", "<leader>ff", builtin.find_files,  { desc = "Find files" })
      vim.keymap.set("n", "<leader>fg", builtin.live_grep,   { desc = "Live grep" })
      vim.keymap.set("n", "<leader>fb", builtin.buffers,     { desc = "Buffers" })
      vim.keymap.set("n", "<leader>fh", builtin.help_tags,   { desc = "Help tags" })
    end,
  },

  -- ----------------------------------------------------------
  -- Status line
  -- ----------------------------------------------------------
  {
    "nvim-lualine/lualine.nvim",
    config = function()
      require("lualine").setup({
        options = { theme = "auto" },
      })
    end,
  },

  -- ----------------------------------------------------------
  -- Git integration
  -- :G status, :G blame, :G diff, etc.
  -- ----------------------------------------------------------
  { "tpope/vim-fugitive" },

})

-- =============================================================
-- LSP (neovim 0.11 native API — no nvim-lspconfig needed)
-- =============================================================

-- Keymaps that activate only when an LSP attaches to a buffer
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    local opts = { buffer = ev.buf }
    vim.keymap.set("n", "gd",         vim.lsp.buf.definition,     opts)  -- go to definition
    vim.keymap.set("n", "gD",         vim.lsp.buf.declaration,    opts)  -- go to declaration
    vim.keymap.set("n", "gi",         vim.lsp.buf.implementation, opts)  -- go to implementation
    vim.keymap.set("n", "K",          vim.lsp.buf.hover,          opts)  -- show docs
    vim.keymap.set("n", "gr",         vim.lsp.buf.references,     opts)  -- find all references
    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename,         opts)  -- rename symbol
    vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action,    opts)  -- code actions / quick fixes
    vim.keymap.set("n", "[d",         vim.diagnostic.goto_prev,   opts)  -- prev diagnostic
    vim.keymap.set("n", "]d",         vim.diagnostic.goto_next,   opts)  -- next diagnostic
  end,
})

-- Enable servers after lazy has finished loading (so cmp-nvim-lsp is available)
vim.api.nvim_create_autocmd("User", {
  pattern  = "LazyDone",
  once     = true,
  callback = function()
    local capabilities = require("cmp_nvim_lsp").default_capabilities()
    vim.lsp.config("*", { capabilities = capabilities })  -- apply to all servers
    vim.lsp.enable({ "kotlin_language_server", "jdtls", "pyright" })

    -- Ruff: disable hover (pyright handles docs) and enable format-on-save
    vim.lsp.config("ruff", {
      on_attach = function(client, bufnr)
        client.server_capabilities.hoverProvider = false
        vim.api.nvim_create_autocmd("BufWritePre", {
          buffer  = bufnr,
          callback = function()
            vim.lsp.buf.format({ async = false })
          end,
        })
      end,
    })
    vim.lsp.enable({ "ruff" })
  end,
})
