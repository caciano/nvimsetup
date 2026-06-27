-- init.lua — Neovim (Copilot + LSP + notas em Markdown)
-- Requisitos: Neovim 0.11+, assinatura do Copilot, Nerd Font, e binários externos
--   (fzf, ripgrep, lazygit, node). Lista completa em guia-nvim.md (seção 10).
-- Instalação:
--   1. cp init.lua ~/.config/nvim/init.lua
--   2. nvim +":Lazy sync" +":Copilot auth"
-- Dica: F1 abre o mapa de atalhos (which-key).

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(lazypath)

-- ════════════════════════════════════════════════════════════════════
--  AJUSTES DO USUÁRIO — edite estas variáveis para personalizar o setup
-- ════════════════════════════════════════════════════════════════════
local notes_dir = vim.fn.expand("~/Documents/Notes")  -- pasta das notas (mdnotes, journal, git)

-- Servidores LSP — o Mason instala e ativa todos. Fonte única usada pelos dois plugins de LSP.
local lsp_servers = {
  "clangd", "pyright", "ts_ls", "rust_analyzer", "gopls",
  "lua_ls", "bashls", "jsonls", "marksman",
}

-- Parsers do Treesitter (realce e indentação estrutural).
local ts_parsers = {
  "c", "cpp", "python", "lua", "vim", "vimdoc", "javascript", "typescript",
  "rust", "go", "bash", "json", "yaml", "markdown", "markdown_inline", "html", "css",
}

-- Helper do atalho <leader>nj: abre/cria o journal do dia.
local function open_today_journal()
  local dir = notes_dir .. "/journal"
  vim.fn.mkdir(dir, "p")
  vim.cmd("edit " .. dir .. "/" .. os.date("%Y-%m-%d") .. ".md")
end

-- Sincronização Git das notas (só age se notes_dir for repo com remoto configurado).
local notes_pulled = false
local function notes_is_repo()
  return vim.fn.isdirectory(notes_dir .. "/.git") == 1
end
local function notes_has_remote()
  if not notes_is_repo() then return false end
  local remotes = vim.fn.systemlist({ "git", "-C", notes_dir, "remote" })
  return vim.v.shell_error == 0 and #remotes > 0
end
-- Pull assíncrono, uma vez por sessão, ao abrir a primeira nota.
local function notes_pull()
  if notes_pulled or not notes_has_remote() then return end
  notes_pulled = true
  vim.system({ "git", "-C", notes_dir, "pull", "--quiet", "--no-rebase" }, {}, function(res)
    vim.schedule(function()
      if res.code == 0 then
        vim.cmd("checktime")  -- recarrega buffers se o pull trouxe alterações
      else
        vim.notify("Notas: git pull falhou — resolva manualmente (ex.: F8/lazygit)", vim.log.levels.WARN)
      end
    end)
  end)
end
-- Push síncrono (usado ao sair, após o commit). timeout evita travar a saída se a rede cair.
local function notes_push()
  if not notes_has_remote() then return end
  local cmd = { "git", "-C", notes_dir, "push", "--quiet" }
  if vim.fn.executable("timeout") == 1 then
    cmd = { "timeout", "15", "git", "-C", notes_dir, "push", "--quiet" }
  end
  vim.fn.system(cmd)
end
-- ════════════════════════════════════════════════════════════════════

require("lazy").setup({

  -- GitHub Copilot — inline completion
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    opts = {
      -- Resolve o Node dinamicamente (baixa manutenção): usa o `node` do PATH;
      -- se não houver, cai no caminho do nvm; por fim, no nome puro.
      copilot_node_command = (vim.fn.exepath("node") ~= "" and vim.fn.exepath("node"))
        or vim.fn.expand("~/.nvm/versions/node/v24.16.0/bin/node"),
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

  -- Notes — mdnotes.nvim (Markdown-native; renderiza via markview/live-preview/treesitter)
  -- Navegar notas (F5) + preview no navegador (F9) + render inline (F10)
  {
    "ymic9963/mdnotes.nvim",
    ft = "markdown",
    cmd = "Mdn",
    -- Upstream doc/mdnotes.txt ships a duplicate help tag (*mdnotes.MdnGetAssetInlineLinkOpts*
    -- is reused on the MdnAssetInlineLink entry), which makes :helptags fail with E154.
    -- Patch it on install/update so lazy's helptags step succeeds. Self-heals on every update.
    build = function(plugin)
      local doc = plugin.dir .. "/doc/mdnotes.txt"
      local f = io.open(doc, "r")
      if f then
        local txt = f:read("*a"); f:close()
        txt = txt:gsub(
          "(MdnAssetInlineLink\t+)%*mdnotes%.MdnGetAssetInlineLinkOpts%*",
          "%1*mdnotes.MdnAssetInlineLink*"
        )
        local w = io.open(doc, "w")
        if w then w:write(txt); w:close() end
      end
      pcall(vim.cmd, "helptags " .. plugin.dir .. "/doc")
    end,
    opts = {
      index_file   = notes_dir .. "/index.md",
      assets_path  = notes_dir .. "/assets",            -- images/PDFs pasted into notes land here
      journal_file = function()                          -- dynamic daily journal
        return notes_dir .. "/journal/" .. os.date("%Y-%m-%d") .. ".md"
      end,
      asset_insert_behaviour = "copy",
      open_behaviour = "buffer",
      date_format = "%a %d %b %Y",
      prefer_lsp = false,             -- use mdnotes' own link/ref functions; marksman still attaches
      auto_list_continuation = true,  -- auto-continue/renumber lists
      default_keymaps = true,         -- buffer-local <leader>m… maps inside Markdown buffers
      autocmds = true,
      toc_depth = 4,
    },
    keys = {
      { "<F5>", function()
          notes_pull()
          require("fzf-lua").files({ cwd = notes_dir, prompt = "Notes> ", hidden = false })
        end, desc = "Browse Notes" },
      { "<leader>nf", function()
          notes_pull()
          require("fzf-lua").live_grep({ cwd = notes_dir, prompt = "Search Notes> " })
        end, desc = "Search Notes" },
      { "<leader>ni", function() vim.cmd("edit " .. notes_dir .. "/index.md") end, desc = "Notes Index" },
      { "<leader>nj", open_today_journal, desc = "Today's Journal" },
      { "<leader>nJ", "<cmd>Mdn journal insert_entry<CR>", desc = "Insert Journal Entry" },
      { "<leader>nt", "<cmd>Mdn toc generate<CR>", desc = "Generate ToC" },
      { "<leader>no", "<cmd>Mdn outliner_toggle<CR>", desc = "Outliner Toggle" },
    },
  },
  -- Preview de Markdown no navegador — live-preview.nvim (sem dependência de Node)
  {
    "brianhuster/live-preview.nvim",
    version = "*",       -- usa a última release estável (não o HEAD da main, que tem regressões)
    cmd = "LivePreview",
    opts = {},  -- previewa Markdown/HTML/AsciiDoc/SVG com atualização ao vivo
    keys = {
      -- F9 idempotente: evita o caminho de "reiniciar" do plugin, onde está o bug de
      -- ciclo de vida do servidor. Para trocar de arquivo, feche antes com <leader>lc.
      { "<F9>", function()
          if vim.bo.filetype ~= "markdown" then
            vim.notify("Live preview: disponível só em arquivos Markdown", vim.log.levels.INFO)
            return
          end
          local ok, lp = pcall(require, "livepreview")
          if ok and lp.is_running and lp.is_running() then
            vim.notify("Live preview já está aberta — use <leader>lc para fechar", vim.log.levels.INFO)
          else
            vim.cmd("LivePreview start")
          end
        end, desc = "Live Preview (browser)" },
      { "<leader>lc", "<cmd>LivePreview close<CR>", desc = "Close Live Preview" },
    },
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
    keys = { { "<F10>", function()
        if vim.bo.filetype ~= "markdown" then
          vim.notify("Markview: disponível só em arquivos Markdown", vim.log.levels.INFO)
          return
        end
        vim.cmd("Markview toggle")
      end, desc = "Inline Preview" } },
  },

  -- LSP — Mason + lspconfig
  { "williamboman/mason.nvim", build = ":MasonUpdate", opts = {} },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    opts = { ensure_installed = lsp_servers },
  },
  {
    "neovim/nvim-lspconfig",
    dependencies = { "williamboman/mason-lspconfig.nvim" },
    config = function()
      -- Anuncia as capabilities de completação do blink.cmp a todos os servidores
      local ok, blink = pcall(require, "blink.cmp")
      if ok then vim.lsp.config("*", { capabilities = blink.get_lsp_capabilities() }) end

      -- lua_ls: impede que a raiz seja a HOME (que ele recusa por ser grande demais) e
      -- o ajusta para editar a própria config (reconhece `vim`, não varre terceiros).
      vim.lsp.config("lua_ls", {
        root_dir = function(bufnr, on_dir)
          local fname = vim.api.nvim_buf_get_name(bufnr)
          local found = vim.fs.root(fname, {
            ".luarc.json", ".luarc.jsonc", ".luacheckrc", "stylua.toml", ".stylua.toml", ".git",
          })
          -- nunca usar HOME ou / como workspace
          if not found or found == vim.env.HOME or found == "/" then
            found = vim.fs.dirname(fname)
          end
          on_dir(found)
        end,
        settings = {
          Lua = {
            runtime = { version = "LuaJIT" },
            diagnostics = { globals = { "vim" } },
            workspace = { checkThirdParty = false, library = { vim.env.VIMRUNTIME .. "/lua" } },
            telemetry = { enable = false },
          },
        },
      })

      for _, server in ipairs(lsp_servers) do
        pcall(function() vim.lsp.enable(server) end)
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

  -- Completion — blink.cmp (Rust fuzzy matcher; LSP + Copilot + snippets + path + buffer)
  {
    "saghen/blink.cmp",
    version = "1.*",                       -- release tag → prebuilt Rust binary, no cargo needed
    event = "InsertEnter",
    dependencies = { "fang2hou/blink-copilot" },
    opts = {
      keymap = {
        preset = "enter",                  -- <CR> aceita, <C-e> esconde, <C-space> abre/mostra docs
        ["<Tab>"]   = { "select_next", "snippet_forward", "fallback" },
        ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
      },
      appearance = { nerd_font_variant = "mono" },
      snippets = { preset = "default" },   -- usa o vim.snippet nativo (0.10+); sem LuaSnip
      sources = {
        default = { "copilot", "lsp", "path", "snippets", "buffer" },
        providers = {
          copilot = { name = "copilot", module = "blink-copilot", async = true, score_offset = 100 },
        },
      },
      completion = {
        menu = { border = "rounded" },
        documentation = { auto_show = true, auto_show_delay_ms = 200, window = { border = "rounded" } },
        accept = { auto_brackets = { enabled = true } },  -- () após confirmar função (substitui o gancho antigo)
      },
      signature = { enabled = true },
    },
  },

  -- Fuzzy finder — fzf-lua (requer o binário `fzf` + `ripgrep`; `fd` opcional)
  {
    "ibhagwan/fzf-lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    cmd = "FzfLua",
    opts = {
      winopts = { preview = { layout = "horizontal", horizontal = "right:60%" } },  -- preview com 60%
    },
    keys = {
      { "<F3>", function() require("fzf-lua").files() end, desc = "Files" },
      { "<F4>", function() require("fzf-lua").live_grep() end, desc = "Grep" },
      { "<C-p>", function() require("fzf-lua").files() end, desc = "Files" },
      { "<C-g>", function() require("fzf-lua").live_grep() end, desc = "Grep" },
      { "<C-b>", function() require("fzf-lua").buffers() end, desc = "Buffers" },
      { "<leader>h", function() require("fzf-lua").help_tags() end, desc = "Help" },
      { "<leader>fw", function() require("fzf-lua").grep_cword() end, desc = "Grep word" },
      { "<leader>fd", function() require("fzf-lua").diagnostics_document() end, desc = "Diagnostics" },
    },
  },

  -- Treesitter — structural highlighting
  -- Pinned to `master`: a branch `main` é a reescrita incompatível que exige o `tree-sitter` CLI;
  -- a `master` está congelada, usa a API clássica abaixo e compila parsers só com um compilador C.
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    build = ":TSUpdate",
    main = "nvim-treesitter.configs",
    opts = {
      ensure_installed = ts_parsers,
      auto_install = true, highlight = { enable = true }, indent = { enable = true },
    },
  },

  -- Git
  { "tpope/vim-fugitive", cmd = { "Git", "G" } },
  {
    "kdheepak/lazygit.nvim",                       -- requer o binário `lazygit` instalado
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = { "LazyGit", "LazyGitCurrentFile" },
    keys = {
      { "<F8>", "<cmd>LazyGit<CR>", desc = "LazyGit" },
      { "<leader>lg", "<cmd>LazyGit<CR>", desc = "LazyGit" },
      { "<leader>lG", "<cmd>LazyGitCurrentFile<CR>", desc = "LazyGit (repo do arquivo)" },
    },
  },
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

  -- File manager — oil.nvim (edita o sistema de arquivos como um buffer; assume o lugar do netrw)
  {
    "stevearc/oil.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    lazy = false,  -- precisa carregar cedo para substituir o netrw ao abrir um diretório
    opts = {
      default_file_explorer = true,
      view_options = { show_hidden = true },
      float = { padding = 4 },
    },
    keys = {
      { "<F6>", function() require("oil").toggle_float() end, desc = "File Manager (flutuante)" },
      { "-", "<cmd>Oil<CR>", desc = "Abrir diretório pai" },
    },
  },

  -- Undo + editing
  { "mbbill/undotree", keys = { { "<F7>", ":UndotreeToggle<CR>" } } },
  { "kylechui/nvim-surround", version = "*", event = "VeryLazy", opts = {} },  -- ys/ds/cs (substitui vim-surround)
  { "echasnovski/mini.align", version = "*", opts = {} },                       -- ga / gA (substitui vim-easy-align)
  -- vim-commentary removido: o Neovim 0.10+ tem comentário nativo (gc, gcc, gbc)
  { "lervag/vimtex", ft = "tex", opts = { view_method = "zathura", compiler_method = "latexmk" } },

  -- Theme & UI
  { "caciano/dante.vim", lazy = false, priority = 1000 },  -- colorscheme dante (carrega no boot)
  { "folke/tokyonight.nvim", lazy = true },
  { "junegunn/seoul256.vim", lazy = true },
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = { theme = "auto", section_separators = { left = "", right = "" }, component_separators = { left = "", right = "" } },
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
  { "folke/which-key.nvim", event = "VeryLazy", opts = { preset = "modern", delay = 500 } },
  -- vim-highlightedyank removido: o autocmd TextYankPost no fim do arquivo já faz isso
  { "windwp/nvim-autopairs", event = "InsertEnter", opts = {} },  -- () de função vem do blink.accept.auto_brackets
}, {
  ui = { border = "rounded" },
  install = { colorscheme = { "dante" } },
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
pcall(vim.cmd.colorscheme, "dante")

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
map("n", "<F1>", "<cmd>WhichKey<CR>", { desc = "Mapa de atalhos" })
map("n", "<F2>", vim.lsp.buf.rename, { desc = "Renomear símbolo (LSP)" })
map("t", "<Esc><Esc>", "<C-\\><C-n>")

-- Autocommands
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

-- Ao abrir uma nota (qualquer arquivo sob notes_dir), faz git pull se houver remoto.
vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function(args)
    local f = vim.fn.fnamemodify(args.file, ":p")
    if f:sub(1, #notes_dir + 1) == notes_dir .. "/" then notes_pull() end
  end,
})

-- Auto-versiona as notas: ao sair do Neovim, commita o que mudou em notes_dir
-- e, se houver remoto, faz push. Síncrono de propósito (VimLeavePre).
vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    if not notes_is_repo() then return end  -- só se for repo git
    vim.fn.system({ "git", "-C", notes_dir, "add", "-A" })
    -- `diff --cached --quiet` retorna != 0 quando há algo staged; evita commit vazio
    vim.fn.system({ "git", "-C", notes_dir, "diff", "--cached", "--quiet" })
    if vim.v.shell_error ~= 0 then
      vim.fn.system({ "git", "-C", notes_dir, "commit", "-q", "-m", "notas: " .. os.date("%Y-%m-%d %H:%M") })
    end
    notes_push()  -- envia commits pendentes (no-op se já estiver tudo no remoto)
  end,
})
