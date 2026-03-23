-- ============================================================
-- Bootstrap lazy.nvim
-- ============================================================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- ============================================================
-- General options
-- ============================================================
local opt = vim.opt

opt.number         = true
opt.expandtab      = true
opt.shiftwidth     = 2
opt.tabstop        = 2
opt.textwidth      = 78
opt.spell          = false
opt.spelllang      = { "en_us" }
opt.backup         = false
opt.swapfile       = false
opt.cursorline     = false
opt.cursorcolumn   = false
opt.relativenumber = false
opt.autoread       = true
opt.timeoutlen     = 200
opt.clipboard:append("unnamedplus")
opt.termguicolors  = true
opt.background     = "dark"
opt.exrc           = true
opt.secure         = true
opt.hlsearch       = true
opt.mouse          = "a"

-- Use ag for keyword lookup if available
if vim.fn.executable("ag") == 1 then
  opt.keywordprg = "ag"
else
  opt.keywordprg = "grep"
end

-- ============================================================
-- Leader
-- ============================================================
vim.g.mapleader = " "

-- ============================================================
-- Keymaps
-- ============================================================
local map = vim.keymap.set

-- Split navigation
map("n", "<c-j>", "<c-w>j")
map("n", "<c-k>", "<c-w>k")
map("n", "<c-h>", "<c-w>h")
map("n", "<c-l>", "<c-w>l")

-- Quickfix navigation
map("n", "<c-n>", ":cnext<cr>")
map("n", "<c-m>", ":cprevious<cr>")
map("n", "<leader>a", ":cclose<cr>")

-- Switch between current and last buffer
map("n", "<leader>,", "<c-^>")

-- Colon shortcut
map("n", ";", ":")
map("v", ";", ":")

-- Re-indent and keep selection
map("v", ">", ">gv")
map("v", "<", "<gv")

-- Diagnostic float
map("n", "<leader>d", vim.diagnostic.open_float)

-- Terminal: esc to normal mode
map("t", "<esc>", "<c-\\><c-n>")

-- DiffOrig command
vim.api.nvim_create_user_command("DiffOrig", function()
  vim.cmd("vert new | set bt=nofile | r # | 0d_ | diffthis | wincmd p | diffthis | wincmd p")
end, {})

-- ============================================================
-- Autocommands
-- ============================================================
local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- Plain text / git commits
autocmd("FileType", {
  pattern = { "text", "gitcommit" },
  callback = function()
    vim.opt_local.autoindent    = true
    vim.opt_local.formatoptions = "a2tw"
    vim.opt_local.spell         = true
  end,
})

-- Markdown
autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.opt_local.spell     = true
    vim.opt_local.textwidth = 0
  end,
})

-- Help
autocmd("FileType", {
  pattern = "help",
  callback = function()
    vim.opt_local.spell = false
  end,
})

-- Treesitter highlighting
autocmd("FileType", {
  callback = function(ev)
    pcall(vim.treesitter.start, ev.buf)
  end,
})

-- Go
autocmd("FileType", {
  pattern = "go",
  callback = function()
    vim.opt_local.autowrite = true
    vim.opt_local.tabstop   = 4
    vim.opt_local.shiftwidth = 4
  end,
})

-- ============================================================
-- Plugins
-- ============================================================
require("lazy").setup({

  -- Colorscheme
  {
    "morhetz/gruvbox",
    priority = 1000,
    config = function()
      vim.g.gruvbox_contrast_dark = "medium"
      vim.cmd("colorscheme gruvbox")
      vim.api.nvim_set_hl(0, "javascriptLabel", { link = "Keyword" })
    end,
  },

  -- Treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter").setup({
        ensure_installed = {
          "go", "python", "javascript", "typescript", "tsx",
          "lua", "bash", "markdown", "json", "yaml", "toml",
          "cpp", "c", "elixir", "ruby", "html", "sql",
          "supercollider", "scss", "css",
        },
      })
    end,
  },

  -- LSP
  {
    "neovim/nvim-lspconfig",
    config = function()
      -- Go
      vim.lsp.config("gopls", {
        settings = {
          gopls = {
            analyses     = { unusedparams = true },
            staticcheck  = true,
            gofumpt      = true,
          },
        },
        on_attach = function(_, bufnr)
          local opts = { buffer = bufnr }
          vim.keymap.set("n", "<leader>m", vim.lsp.buf.implementation, opts)
          vim.keymap.set("n", "<leader>i", vim.lsp.buf.hover, opts)
          vim.keymap.set("n", "<leader>e", vim.lsp.buf.rename, opts)
          vim.keymap.set("n", "<leader>pc", vim.lsp.buf.incoming_calls, opts)
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
          vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
        end,
      })
      vim.lsp.enable("gopls")

      -- C++
      vim.lsp.config("clangd", {
        cmd = { "clangd", "--background-index", "--clang-tidy" },
        on_attach = function(_, bufnr)
          local opts = { buffer = bufnr }
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
          vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
          vim.keymap.set("n", "<leader>i", vim.lsp.buf.hover, opts)
          vim.keymap.set("n", "<leader>e", vim.lsp.buf.rename, opts)
          vim.keymap.set("n", "<leader>m", vim.lsp.buf.implementation, opts)
        end,
      })
      vim.lsp.enable("clangd")

      -- JS/TS
      vim.lsp.config("ts_ls", {
        on_attach = function(_, bufnr)
          local opts = { buffer = bufnr }
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
          vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
          vim.keymap.set("n", "<leader>i", vim.lsp.buf.hover, opts)
          vim.keymap.set("n", "<leader>e", vim.lsp.buf.rename, opts)
          vim.keymap.set("n", "<leader>m", vim.lsp.buf.implementation, opts)
        end,
      })
      vim.lsp.enable("ts_ls")

      -- Format on save
      vim.api.nvim_create_autocmd("BufWritePre", {
        pattern = { "*.go" },
        callback = function() vim.lsp.buf.format({ async = false }) end,
      })
      vim.api.nvim_create_autocmd("BufWritePre", {
        pattern = { "*.c", "*.cc", "*.cpp", "*.h", "*.hpp" },
        callback = function() vim.lsp.buf.format({ async = false }) end,
      })
      vim.api.nvim_create_autocmd("BufWritePre", {
        pattern = { "*.ex", "*.exs", "*.heex" },
        callback = function() vim.lsp.buf.format({ async = false }) end,
      })
    end,
  },

  -- Formatting / autofix
  {
    "stevearc/conform.nvim",
    config = function()
      local conform = require("conform")
      conform.setup({
        formatters = {
          eslint_fix = {
            command = "npx",
            args = { "eslint", "--fix", "$FILENAME" },
            stdin = false,
            exit_codes = { 0, 1 },
          },
        },
        formatters_by_ft = {
          javascript      = { "eslint_fix" },
          javascriptreact = { "eslint_fix" },
          typescript      = { "eslint_fix" },
          typescriptreact = { "eslint_fix" },
        },
      })
      vim.api.nvim_create_autocmd("BufWritePre", {
        pattern = { "*.js", "*.jsx", "*.ts", "*.tsx" },
        callback = function(args)
          conform.format({ bufnr = args.buf, async = false, lsp_fallback = false })
        end,
      })
    end,
  },

  -- Linting
  {
    "mfussenegger/nvim-lint",
    config = function()
      local lint = require("lint")
      lint.linters.eslint = vim.tbl_deep_extend("force", lint.linters.eslint, {
        cwd = function(params)
          return vim.fs.dirname(params.filename)
        end,
      })
      lint.linters_by_ft = {
        javascript      = { "eslint" },
        javascriptreact = { "eslint" },
        typescript      = { "eslint" },
        typescriptreact = { "eslint" },
      }
      vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost" }, {
        callback = function()
          lint.try_lint()
        end,
      })
    end,
  },

  -- Git signs in gutter
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup()
    end,
  },

  -- Comments
  {
    "numToStr/Comment.nvim",
    config = function()
      require("Comment").setup()
    end,
  },

  -- Git
  { "tpope/vim-fugitive" },

  -- File explorer
  {
    "scrooloose/nerdtree",
    config = function()
      vim.g.NERDTreeShowHidden = 1
      vim.keymap.set("n", "<leader>t", ":NERDTreeToggle .<cr>")
    end,
  },

  -- fzf
  {
    "junegunn/fzf.vim",
    dependencies = { "junegunn/fzf" },
    config = function()
      vim.opt.rtp:append(vim.env.FZF_HOME or "")
      vim.opt.rtp:append(vim.fn.expand("~/.fzf"))

      vim.api.nvim_create_user_command("Files", function(opts)
        vim.fn["fzf#vim#files"]("", { source = "ag --hidden -f -g ''" }, opts.bang)
      end, { bang = true, nargs = "*" })

      vim.api.nvim_create_user_command("Ag", function(opts)
        vim.fn["fzf#vim#ag"](opts.args, "--hidden", opts.bang and 1 or 0)
      end, { bang = true, nargs = "*" })

      vim.keymap.set("n", "<leader><space>", ":Files<cr>")
      vim.keymap.set("n", "<leader>/", ":Ag ")
      vim.keymap.set("n", "<leader>colors", ":Colors<cr>")
    end,
  },

  -- Tagbar
  {
    "majutsushi/tagbar",
    config = function()
      vim.g.tagbar_position = "rightbelow vertical"
      vim.keymap.set("n", "<leader>o", ":TagbarToggle<cr>")
    end,
  },

  -- tmux navigation
  { "christoomey/vim-tmux-navigator" },

  -- Markdown preview
  {
    "iamcco/markdown-preview.nvim",
    build = function() vim.fn["mkdp#util#install"]() end,
    config = function()
      vim.g.mkdp_browser = ""
      vim.keymap.set("n", "<leader>pre", "<Plug>MarkdownPreviewToggle")
    end,
  },

  -- SuperCollider
  { "sbl/scvim" },

  -- CUE filetype
  { "jjo/vim-cue" },

  -- Elixir (LSP + better indent via elixir-tools)
  {
    "elixir-tools/elixir-tools.nvim",
    version = "*",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("elixir").setup({
        nextls = { enable = false },
        elixirls = {
          enable = true,
          cmd = { "elixir-ls" },
          on_attach = function(_, bufnr)
            local opts = { buffer = bufnr }
            vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
            vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
            vim.keymap.set("n", "<leader>i", vim.lsp.buf.hover, opts)
            vim.keymap.set("n", "<leader>e", vim.lsp.buf.rename, opts)
            vim.keymap.set("n", "<leader>m", vim.lsp.buf.implementation, opts)
          end,
        },
      })
    end,
  },

}, {
  -- lazy.nvim options
  ui = { border = "rounded" },
})

-- ============================================================
-- Load local overrides if present
-- ============================================================
local overrides = vim.fn.expand("~/.config/nvim/local_overrides.lua")
if vim.fn.filereadable(overrides) == 1 then
  dofile(overrides)
end
