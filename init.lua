-- init.lua — Neovim with GitHub Copilot

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({

  -- GitHub Copilot — inline completion
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    opts = {
      copilot_node_command = "/home/caciano/.nvm/versions/node/v24.16.0/bin/node",
      suggestion = {
        enabled = true, auto_trigger = true, hide_during_completion = true,
        keymap = {
          accept = "<C-l>", accept_word = "<C-k>", accept_line = "<C-j>",
          next = "<M-]>", prev = "<M-[>", dismiss = "<C-]>",
        },
      },
      panel = { enabled = true, auto_refresh = true },
      filetypes = { yaml = false, markdown = true, help = false, gitcommit = true, gitrebase = false },
    },
  },
  { "zbirenbaum/copilot-cmp", dependencies = { "zbirenbaum/copilot.lua" } },

  -- CopilotChat — explain, test, review, refactor
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    dependencies = { "zbirenbaum/copilot.lua", "nvim-lua/plenary.nvim" },
    cmd = { "CopilotChat", "CopilotChatExplain", "CopilotChatTests", "CopilotChatReview", "CopilotChatRefactor" },
    opts = {
      auto_insert_mode = true, show_help = true, context = "buffer",
      question_header = "## You ", answer_header = "## Copilot ", separator = "---",
      model = "gpt-5-mini",
    },
    keys = {
      { "<leader>cc", "<cmd>CopilotChat<CR>",         mode = { "n", "v" }, desc = "Chat" },
      { "<leader>ce", "<cmd>CopilotChatExplain<CR>",  mode = { "v" },     desc = "Explain" },
      { "<leader>ct", "<cmd>CopilotChatTests<CR>",    mode = { "v" },     desc = "Tests" },
      { "<leader>cr", "<cmd>CopilotChatReview<CR>",   mode = { "v" },     desc = "Review" },
      { "<leader>cR", "<cmd>CopilotChatRefactor<CR>", mode = { "v" },     desc = "Refactor" },
      { "<leader>cT", "<cmd>CopilotChatToggle<CR>",   mode = { "n" },     desc = "Toggle Chat" },
      { "<leader>cC", "<cmd>CopilotChatReset<CR>",    mode = { "n" },     desc = "Reset Chat" },
    },
  },

  -- Notes (F5) + Markdown browser preview (F4) + inline preview (F10)
  {
    "xolox/vim-notes",
    dependencies = { "xolox/vim-misc" },
    cmd = "RecentNotes",
    init = function() vim.g.notes_directories = { vim.fn.expand("~/Documents/Notes") } end,
    keys = {
      { "<F5>", "<cmd>RecentNotes<CR>", desc = "Recent Notes" },
      { "<leader>nn", "<cmd>Note<CR>", desc = "New Note" },
    },
  },
  {
    "iamcco/markdown-preview.nvim",
    lazy = false,
    build = "cd app && npm install",
    init = function()
      vim.g.mkdp_command_for_global = 1
      vim.g.mkdp_auto_close = 0
    end,
  },
  {
    "OXY2DEV/markview.nvim",
    lazy = false,
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {
      preview = { filetypes = { "markdown", "quarto", "rmd", "latex", "html", "typst" } },
      modes = { hybrid = { enable = true, hybrid_modes = { "n", "i", "v" } } },
      icons = { enable = true },
      callbacks = { on_enable = function() vim.cmd("setlocal wrap linebreak") end },
    },
    keys = { { "<F10>", "<cmd>Markview toggle<CR>", desc = "Inline Preview" } },
  },

  -- LSP — Mason + lspconfig
  { "williamboman/mason.nvim", build = ":MasonUpdate", opts = {} },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    opts = { ensure_installed = { "clangd", "pyright", "ts_ls", "rust_analyzer", "gopls", "lua_ls", "bashls", "jsonls", "marksman" } },
  },
  {
    "neovim/nvim-lspconfig",
    dependencies = { "williamboman/mason-lspconfig.nvim" },
    config = function()
      for _, server in ipairs({ "clangd", "pyright", "ts_ls", "rust_analyzer", "gopls", "lua_ls", "bashls", "jsonls", "marksman" }) do
        pcall(function() vim.lsp.config[server] = {}; vim.lsp.enable(server) end)
      end
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(ev)
          local o = { buffer = ev.buf }
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, o)
          vim.keymap.set("n", "gr", vim.lsp.buf.references, o)
          vim.keymap.set("n", "gi", vim.lsp.buf.implementation, o)
          vim.keymap.set("n", "K", vim.lsp.buf.hover, o)
          vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, o)
          vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, o)
          vim.keymap.set("n", "<leader>cf", vim.lsp.buf.format, o)
        end,
      })
    end,
  },

  -- Completion — nvim-cmp (Copilot + LSP + buffer)
  {
    "hrsh7th/nvim-cmp",
    dependencies = { "hrsh7th/cmp-nvim-lsp", "hrsh7th/cmp-buffer", "hrsh7th/cmp-path", "L3MON4D3/LuaSnip", "saadparwaiz1/cmp_luasnip" },
    config = function()
      local cmp = require("cmp")
      cmp.setup({
        snippet = { expand = function(args) require("luasnip").lsp_expand(args.body) end },
        window = { completion = cmp.config.window.bordered(), documentation = cmp.config.window.bordered() },
        mapping = {
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping(function(f) if cmp.visible() then cmp.select_next_item() else f() end end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(f) if cmp.visible() then cmp.select_prev_item() else f() end end, { "i", "s" }),
        },
        sources = { { name = "copilot" }, { name = "nvim_lsp" }, { name = "luasnip" }, { name = "buffer" }, { name = "path" } },
      })
    end,
  },

  -- Telescope — fuzzy finder
  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.8", dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<C-p>", function() require("telescope.builtin").find_files() end, desc = "Files" },
      { "<C-g>", function() require("telescope.builtin").live_grep() end, desc = "Grep" },
      { "<C-b>", function() require("telescope.builtin").buffers() end, desc = "Buffers" },
      { "<leader>h", function() require("telescope.builtin").help_tags() end, desc = "Help" },
      { "<leader>fw", function() require("telescope.builtin").grep_string() end, desc = "Grep word" },
      { "<leader>fd", function() require("telescope.builtin").diagnostics() end, desc = "Diagnostics" },
    },
  },

  -- Treesitter — structural highlighting
  {
    "nvim-treesitter/nvim-treesitter", build = ":TSUpdate",
    opts = {
      ensure_installed = { "c", "cpp", "python", "lua", "vim", "vimdoc", "javascript", "typescript", "rust", "go", "bash", "json", "yaml", "markdown", "markdown_inline", "html", "css" },
      auto_install = true, highlight = { enable = true }, indent = { enable = true },
    },
  },

  -- Git
  { "tpope/vim-fugitive", cmd = { "Git", "G" } },
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      on_attach = function(bufnr)
        local gs = package.loaded.gitsigns; local m = vim.keymap.set
        m("n", "]c", gs.next_hunk, { buffer = bufnr })
        m("n", "[c", gs.prev_hunk, { buffer = bufnr })
        m({ "n", "v" }, "<leader>hs", gs.stage_hunk, { buffer = bufnr })
        m({ "n", "v" }, "<leader>hr", gs.reset_hunk, { buffer = bufnr })
        m("n", "<leader>hp", gs.preview_hunk, { buffer = bufnr })
        m("n", "<leader>hb", gs.blame_line, { buffer = bufnr })
      end,
    },
  },

  -- File tree
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = { { "<F6>", ":NvimTreeToggle<CR>" } },
    opts = { filters = { dotfiles = false }, disable_netrw = true, hijack_netrw = true, view = { width = 35, side = "left" } },
  },

  -- Undo + editing
  { "mbbill/undotree", keys = { { "<F7>", ":UndotreeToggle<CR>" } } },
  "tpope/vim-surround",
  "tpope/vim-commentary",
  "jiangmiao/auto-pairs",
  { "junegunn/vim-easy-align", keys = { { "ga", "<Plug>(EasyAlign)", mode = { "n", "x" } } } },
  { "lervag/vimtex", ft = "tex", opts = { view_method = "zathura", compiler_method = "latexmk" } },

  -- Theme & UI
  { "folke/tokyonight.nvim", lazy = true },
  { "junegunn/seoul256.vim", lazy = true },
  { "vim-scripts/dante.vim", lazy = true },
  { "vim-scripts/zenburn", lazy = true },
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = { theme = "seoul256", section_separators = { left = "", right = "" }, component_separators = { left = "", right = "" } },
      sections = { lualine_a = { "mode" }, lualine_b = { "branch", "diff", "diagnostics" }, lualine_c = { "filename" }, lualine_x = { "encoding", "fileformat", "filetype" }, lualine_y = { "progress" }, lualine_z = { "location" } },
    },
  },
  {
    "lukas-reineke/indent-blankline.nvim",
    config = function()
      local ok, ibl = pcall(require, "ibl")
      if ok then ibl.setup({ indent = { char = "│" }, scope = { enabled = true, show_start = true, show_end = true } }) end
    end,
  },

  -- Utilities
  { "machakann/vim-highlightedyank", config = function() vim.g.highlightedyank_highlight_duration = 300 end },
  { "folke/which-key.nvim", event = "VeryLazy", opts = { preset = "modern", delay = 500 } },
  { "windwp/nvim-autopairs", event = "InsertEnter", opts = {} },
sdd
}, {
  ui = { border = "rounded" },
  install = { colorscheme = { "seoul256" } },
  performance = { rtp = { disabled_plugins = { "gzip", "matchit", "matchparen", "netrwPlugin", "tarPlugin", "tohtml", "tutor", "zipPlugin" } } },
})

-- Options
vim.opt.clipboard = "unnamedplus"
vim.opt.mouse = "a"
vim.opt.confirm = true
vim.opt.history = 10000
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.scrolloff = 5
vim.opt.sidescrolloff = 5
vim.opt.wrap = true
vim.opt.linebreak = true
vim.opt.textwidth = 78
vim.opt.laststatus = 3
vim.opt.showmode = false
vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"
vim.opt.list = true
vim.opt.listchars = "tab:··,trail:·,extends:»,precedes:«,nbsp:+"
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.completeopt = { "menu", "menuone", "noselect" }
vim.opt.colorcolumn = "80"
vim.cmd("colorscheme seoul256")

-- Keymaps
local map = vim.keymap.set
vim.g.mapleader = " "
vim.g.maplocalleader = " "

map("n", "<s-down>", "<c-w>j")
map("n", "<s-up>", "<c-w>k")
map("n", "<s-left>", "<c-w>h")
map("n", "<s-right>", "<c-w>l")
map("n", "<c-s-right>", ":bnext<CR>")
map("n", "<c-s-left>", ":bprev<CR>")
map("n", "<leader>q", ":bp|bd #<CR>")
map("n", "<leader><space>", ":nohlsearch<CR>")
map("n", "<F4>", function()
  if vim.fn.exists(":MarkdownPreview") == 2 then
    vim.cmd("MarkdownPreview")
  else
    vim.notify("markdown-preview.nvim not ready", vim.log.levels.WARN)
  end
end)
map("t", "<Esc><Esc>", "<C-\\><C-n>")

-- Autocommands
vim.api.nvim_create_autocmd("BufEnter", {
  callback = function()
    local layout = vim.api.nvim_call_function("winlayout", {})
    if layout[1] == "leaf"
        and vim.api.nvim_buf_get_option(vim.api.nvim_win_get_buf(layout[2]), "filetype") == "NvimTree"
        and layout[3] == nil then
      vim.cmd("quit")
    end
  end,
})
vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(0) then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function() vim.highlight.on_yank({ higroup = "IncSearch", timeout = 300 }) end,
})
