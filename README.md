# Neovim config — Copilot · LSP · Markdown notes

A single-file [Neovim](https://neovim.io/) configuration built around GitHub Copilot,
a fast native-LSP setup, and a Markdown note-taking workflow. Modern, lazy-loaded, and
designed to be easy to maintain — all the knobs you'll touch live in one block at the top.

> Requires Neovim **0.11+** · plugin manager: [lazy.nvim](https://github.com/folke/lazy.nvim) (bootstraps itself)

Pairs with the [**dante** colorscheme](#colorscheme) (a warm, dark theme included as a companion).

---

## Features

- **Completion** — [blink.cmp](https://github.com/saghen/blink.cmp): Rust fuzzy matcher, LSP + Copilot + snippets + path + buffer, auto-brackets, signature help.
- **AI** — [copilot.lua](https://github.com/zbirenbaum/copilot.lua) inline suggestions (ghost text) + [CopilotChat](https://github.com/CopilotC-Nvim/CopilotChat.nvim) for explain/test/review/refactor.
- **LSP** — native `vim.lsp` (0.11) with [Mason](https://github.com/williamboman/mason.nvim) auto-installing servers; capabilities wired to blink.cmp.
- **Finder** — [fzf-lua](https://github.com/ibhagwan/fzf-lua) for files, live grep, buffers, diagnostics.
- **Files** — [oil.nvim](https://github.com/stevearc/oil.nvim): edit the filesystem like a buffer.
- **Git** — [gitsigns](https://github.com/lewis6991/gitsigns.nvim) + [lazygit](https://github.com/kdheepak/lazygit.nvim) + [fugitive](https://github.com/tpope/vim-fugitive).
- **Notes** — [mdnotes.nvim](https://github.com/ymic9963/mdnotes.nvim) + [markview](https://github.com/OXY2DEV/markview.nvim) inline render + [live-preview](https://github.com/brianhuster/live-preview.nvim) (browser, no Node) + automatic Git versioning of your notes folder.
- **Editing** — Tree-sitter highlighting, [nvim-surround](https://github.com/kylechui/nvim-surround), [mini.align](https://github.com/echasnovski/mini.align), native commenting (`gc`), autopairs.
- **UI** — [lualine](https://github.com/nvim-lualine/lualine.nvim), [which-key](https://github.com/folke/which-key.nvim), [indent-blankline](https://github.com/lukas-reineke/indent-blankline.nvim).

> The config file's inline comments are written in Portuguese; this README is the English reference.

---

## Installation

```bash
# 1. Back up any existing config
mv ~/.config/nvim ~/.config/nvim.bak 2>/dev/null

# 2. Drop in the config
mkdir -p ~/.config/nvim
cp init.lua ~/.config/nvim/init.lua

# 3. (Optional) add the companion colorscheme — see the dante repo
mkdir -p ~/.config/nvim/colors
cp dante.lua ~/.config/nvim/colors/dante.lua

# 4. First launch: plugins install automatically, then authenticate Copilot
nvim +"Lazy sync" +"Copilot auth"
```

The default theme is `dante`. If you don't install `dante.lua`, set `theme` (see
[Customization](#customization)) to a colorscheme you have, e.g. `"tokyonight"` or `"seoul256"`,
both of which ship with this config.

---

## Software dependencies (Ubuntu 24.04)

Neovim is just the editor; several plugins call external programs. Install per need.

### Essentials

```bash
# Neovim 0.11+ (the default Ubuntu repo ships an older version)
sudo add-apt-repository ppa:neovim-ppa/unstable -y
sudo apt update && sudo apt install -y neovim

# Base tooling: git/curl for lazy & Mason, build-essential to compile Tree-sitter parsers
sudo apt install -y git curl unzip build-essential
```

### Search & icons

```bash
sudo apt install -y fzf ripgrep fd-find       # fzf-lua engine + grep (+ optional fd)
ln -s "$(command -v fdfind)" ~/.local/bin/fd  # Ubuntu names the binary `fdfind`

sudo apt install -y wl-clipboard              # system clipboard (Wayland; use xclip on X11)
```

A **Nerd Font** is required for icons (oil, fzf-lua, lualine, markview):

```bash
mkdir -p ~/.local/share/fonts && cd /tmp
curl -fLo Ubuntu.zip https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Ubuntu.zip
unzip -o Ubuntu.zip -d ~/.local/share/fonts/UbuntuNerdFont && fc-cache -f
# Then select "Ubuntu Nerd Font" (or another Nerd Font) in your terminal.
```

### Git UI (lazygit)

```bash
LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" \
  | grep -Po '"tag_name": *"v\K[^"]*')
curl -fLo /tmp/lazygit.tar.gz \
  "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
tar -xf /tmp/lazygit.tar.gz -C /tmp lazygit && sudo install /tmp/lazygit -D -t /usr/local/bin/
```

### Copilot

GitHub Copilot needs **Node.js 18+**. The config resolves `node` from your `PATH`
automatically (works with `nvm`), so just make sure Node is available in the shell that
starts Neovim. `live-preview` needs **no** Node.

### Per-language LSP (optional)

Mason downloads most servers; a few need a toolchain:

```bash
sudo apt install -y clangd golang-go                 # C/C++, Go
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh   # Rust (rust_analyzer)
# Python/TS/Bash/JSON servers use Node; lua_ls & marksman are downloaded by Mason.
```

### LaTeX (optional, for vimtex)

```bash
sudo apt install -y zathura latexmk texlive-latex-recommended texlive-latex-extra
```

Verify everything with `:checkhealth`, `:Mason`, and `:Copilot status`.

---

## Keymaps

Leader is `<Space>`. Press `F1` (or `<Space>`) any time to see the live key map (which-key).

### Function keys

| Key | Action | Alt |
|-----|--------|-----|
| `F1` | Key map (which-key) | — |
| `F2` | LSP rename | `<leader>rn` |
| `F3` | Find files | `Ctrl-p` |
| `F4` | Live grep (project) | `Ctrl-g` |
| `F5` | Browse notes | — |
| `F6` | File manager (oil, float) | `-` (parent dir) |
| `F7` | Undo tree | — |
| `F8` | LazyGit | `<leader>lg` |
| `F9` | Live preview in browser (Markdown) | — |
| `F10` | Inline Markdown render (markview) | — |

### Completion (insert mode)

| Key | Action |
|-----|--------|
| `Tab` / `Shift-Tab` | Next / previous item (and snippet jump) |
| `Enter` | Accept |
| `Ctrl-Space` | Open menu / show docs |
| `Ctrl-e` | Hide menu |
| `Ctrl-l` / `Ctrl-k` / `Ctrl-j` | Copilot: accept all / word / line |
| `Alt-]` / `Alt-[` | Copilot: next / previous suggestion |

### LSP (buffers with a server)

| Key | Action |
|-----|--------|
| `gd` `gr` `gi` | Definition · references · implementation |
| `K` | Hover docs |
| `<leader>rn` | Rename · `<leader>ca` code action · `<leader>cf` format |

### Git

| Key | Action |
|-----|--------|
| `]c` / `[c` | Next / previous hunk |
| `<leader>hp` `<leader>hs` `<leader>hr` `<leader>hb` | Preview · stage · reset · blame hunk |
| `<leader>lg` | LazyGit · `:Git` opens fugitive |

### Notes (`<Space>n…`)

| Key | Action |
|-----|--------|
| `F5` / `<leader>nf` | Browse / search notes |
| `<leader>ni` `<leader>nj` `<leader>nJ` | Index · today's journal · insert journal entry |
| `<leader>nt` `<leader>no` | Generate ToC · outliner toggle |
| `<leader>m…` | mdnotes maps inside Markdown buffers (links, headings, tasks, bold/italic) |

### Editing & navigation

| Key | Action |
|-----|--------|
| `gcc` / `gc{motion}` | Toggle comment (native) |
| `ys` / `ds` / `cs` | Add / delete / change surround |
| `ga` / `gA` | Align (mini.align) |
| `Shift`+arrows | Move between windows |
| `Ctrl-Shift-Left/Right` | Previous / next buffer |
| `<leader>q` | Close buffer · `<leader><Space>` clear search highlight |

### CopilotChat (`<Space>c…`)

`cc` chat · `ce` explain · `ct` tests · `cr` review · `cR` refactor · `cT` toggle · `cC` reset
(visual selection for `ce/ct/cr/cR`).

---

## Notes workflow & Git versioning

Notes live in `~/Documents/Notes` (configurable). On exit, Neovim auto-commits any changes
inside that folder — initialize the repo once:

```bash
cd ~/Documents/Notes && git init && git add -A && git commit -m "notes: initial"
```

Write in Markdown, link notes with `[[wiki-links]]`, render inline with `F10`, preview in the
browser with `F9`. A daily journal is one keystroke away (`<leader>nj`).

---

## Customization

Everything you'll commonly tweak is in the **user-settings block** at the top of `init.lua`:

```lua
local notes_dir = vim.fn.expand("~/Documents/Notes")  -- notes folder
local theme     = "dante"                             -- colorscheme (lualine follows it)
local lsp_servers = { "clangd", "pyright", ... }      -- single source of truth
local ts_parsers  = { "c", "lua", "markdown", ... }   -- Tree-sitter parsers
```

Change the theme, add/remove an LSP server, or point the notes folder elsewhere — each in
exactly one place.

---

## Colorscheme

This config defaults to **dante**, a warm dark theme maintained as a companion project:
[link to the dante repo]. Drop `dante.lua` into `~/.config/nvim/colors/` (see Installation).
Any other colorscheme works too — just change `theme`.

---

## Credits

Built on the work of the plugin authors linked in [Features](#features), and on
[folke/lazy.nvim](https://github.com/folke/lazy.nvim). Thanks to all of them.

## License

Released under the MIT License. Do whatever you like; attribution appreciated.
