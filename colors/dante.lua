-- dante.lua — colorscheme escuro, quente, para programar
-- Autoria original: Caciano Machado <caciano@inf.ufrgs.br> (2002, dante.vim)
-- Modernização (2026): paleta resolvida para hex, contraste ajustado e suporte a
--   Treesitter (@…), tokens semânticos de LSP, diagnostics e plugins do setup.
-- Instalação: salve como  ~/.config/nvim/colors/dante.lua
-- Requer: termguicolors (truecolor). Ative o tema com  :colorscheme dante

vim.cmd("highlight clear")
if vim.fn.exists("syntax_on") == 1 then vim.cmd("syntax reset") end
vim.o.background = "dark"
vim.o.termguicolors = true
vim.g.colors_name = "dante"

-- ── Paleta (inspirada no dante original, refinada para contraste em fundo preto) ──
local c = {
  -- bases
  bg          = "#0a0a0a",  -- preto suavizado (reduz "halation" vs. #000)
  bg_dark     = "#060606",  -- janelas/painéis inativos
  bg_float    = "#121212",  -- popups e janelas flutuantes
  bg_cursor   = "#141414",  -- CursorLine
  bg_sel      = "#33291c",  -- seleção visual (tom quente, legível)
  bg_colorcol = "#161616",  -- guia da coluna 80
  bg_menusel  = "#3a2f12",  -- item selecionado no menu (dourado escuro)

  fg          = "#cdaf95",  -- peachpuff3 — a cor de leitura, tan quente
  fg_dim      = "#8b8b83",  -- ivory4 — texto de apoio / números de linha
  fg_gutter   = "#4d4d4d",  -- gray30 — gutter, caracteres não-texto
  fg_faint    = "#2e2e2e",  -- linhas/separadores muito discretos

  -- acentos (mantêm a semântica do dante)
  teal        = "#1f9f9f",  -- cyan4 → comentários
  gold        = "#d2b21a",  -- gold3 → palavras-chave / statements
  goldenrod   = "#eead0e",  -- darkgoldenrod2 → busca / destaques
  green       = "#83c44d",  -- chartreuse3 → tipos
  olive       = "#a6b56e",  -- darkolivegreen4 (clareado) → funções
  red         = "#df574a",  -- firebrick3 (clareado) → strings / constantes
  red_bright  = "#ee4b3b",  -- red2 → números / erros
  blue        = "#5a8fd6",  -- dodgerblue4 (clareado) → pré-processador
  royal       = "#6a8fff",  -- royalblue → diretórios / links
  brown       = "#c87f4a",  -- sienna (clareado) → special / delimitadores
  orange      = "#e0894a",  -- booleanos / built-ins
  aqua        = "#79e8c4",  -- aquamarine → títulos
  purple      = "#9d7cd8",  -- slateblue (clareado) → sublinhados / membros

  -- diff (tons dessaturados que funcionam no escuro)
  diff_add    = "#16301c",
  diff_change = "#26243a",
  diff_delete = "#3a1717",
  diff_text   = "#2e4a2e",
}

-- ── Helpers ──
local function hi(group, spec) vim.api.nvim_set_hl(0, group, spec) end
local function link(group, target) vim.api.nvim_set_hl(0, group, { link = target }) end

-- ════════════════════════════════════════════════════════════════════
--  Editor / UI
-- ════════════════════════════════════════════════════════════════════
hi("Normal",        { fg = c.fg, bg = c.bg })
hi("NormalNC",      { fg = c.fg, bg = c.bg })
hi("NormalFloat",   { fg = c.fg, bg = c.bg_float })
hi("FloatBorder",   { fg = c.fg_gutter, bg = c.bg_float })
hi("FloatTitle",    { fg = c.gold, bg = c.bg_float, bold = true })
hi("Cursor",        { fg = c.bg, bg = c.fg })
hi("lCursor",       { fg = c.bg, bg = c.fg })
hi("CursorLine",    { bg = c.bg_cursor })
hi("CursorColumn",  { bg = c.bg_cursor })
hi("ColorColumn",   { bg = c.bg_colorcol })
hi("LineNr",        { fg = c.fg_gutter })
hi("CursorLineNr",  { fg = c.goldenrod, bold = true })   -- linha atual em destaque (usabilidade)
hi("SignColumn",    { bg = c.bg })
hi("FoldColumn",    { fg = c.fg_gutter, bg = c.bg })
hi("Folded",        { fg = c.teal, bg = c.bg_float })    -- corrige o fundo branco do original
hi("VertSplit",     { fg = c.fg_faint })
hi("WinSeparator",  { fg = c.fg_faint })
hi("NonText",       { fg = c.fg_gutter })
hi("SpecialKey",    { fg = c.fg_gutter })
hi("Whitespace",    { fg = c.fg_faint })
hi("EndOfBuffer",   { fg = c.bg })
hi("Directory",     { fg = c.royal })
hi("Title",         { fg = c.aqua, bold = true })
hi("Conceal",       { fg = c.fg_dim })
hi("MatchParen",    { fg = c.goldenrod, bg = c.fg_faint, bold = true })

-- Busca e seleção
hi("Search",        { fg = c.bg, bg = c.gold })
hi("IncSearch",     { fg = c.bg, bg = c.goldenrod, bold = true })
hi("CurSearch",     { fg = c.bg, bg = c.goldenrod, bold = true })
hi("Visual",        { bg = c.bg_sel })
hi("VisualNOS",     { bg = c.bg_sel })

-- Mensagens
hi("ModeMsg",       { fg = c.fg_dim, bold = true })
hi("MoreMsg",       { fg = c.green })
hi("Question",      { fg = c.green, bold = true })
hi("WarningMsg",    { fg = c.orange, bold = true })
hi("ErrorMsg",      { fg = c.red_bright, bold = true })
hi("MsgArea",       { fg = c.fg })

-- Statusline / tabline (o lualine usa "auto", mas isto cobre contextos sem ele)
hi("StatusLine",    { fg = c.fg, bg = c.bg_float })
hi("StatusLineNC",  { fg = c.fg_dim, bg = c.bg_dark })
hi("TabLine",       { fg = c.fg_dim, bg = c.bg_dark })
hi("TabLineSel",    { fg = c.gold, bg = c.bg, bold = true })
hi("TabLineFill",   { bg = c.bg_dark })
hi("WildMenu",      { fg = c.bg, bg = c.gold })

-- Menu de completação (Pmenu / blink.cmp)
hi("Pmenu",         { fg = c.fg, bg = c.bg_float })
hi("PmenuSel",      { fg = c.fg, bg = c.bg_menusel, bold = true })
hi("PmenuSbar",     { bg = c.bg_float })
hi("PmenuThumb",    { bg = c.fg_gutter })
hi("PmenuKind",     { fg = c.olive, bg = c.bg_float })
hi("PmenuExtra",    { fg = c.fg_dim, bg = c.bg_float })

-- ════════════════════════════════════════════════════════════════════
--  Sintaxe legada (Vim) — base que os grupos @… herdam
-- ════════════════════════════════════════════════════════════════════
hi("Comment",      { fg = c.teal, italic = true })
hi("Constant",     { fg = c.red })
hi("String",       { fg = c.red })
hi("Character",    { fg = c.red })
hi("Number",       { fg = c.red_bright })
hi("Float",        { fg = c.red_bright })
hi("Boolean",      { fg = c.orange })
hi("Identifier",   { fg = c.olive })
hi("Function",     { fg = c.olive })
hi("Statement",    { fg = c.gold })
hi("Conditional",  { fg = c.gold })
hi("Repeat",       { fg = c.gold })
hi("Label",        { fg = c.gold })
hi("Operator",     { fg = c.fg })
hi("Keyword",      { fg = c.gold })
hi("Exception",    { fg = c.gold })
hi("PreProc",      { fg = c.blue })
hi("Include",      { fg = c.blue })
hi("Define",       { fg = c.blue })
hi("Macro",        { fg = c.blue })
hi("PreCondit",    { fg = c.blue })
hi("Type",         { fg = c.green })
hi("StorageClass", { fg = c.green })
hi("Structure",    { fg = c.green })
hi("Typedef",      { fg = c.green })
hi("Special",      { fg = c.brown })
hi("SpecialChar",  { fg = c.brown })
hi("Tag",          { fg = c.gold })
hi("Delimiter",    { fg = c.fg_dim })
hi("SpecialComment",{ fg = c.teal, bold = true })
hi("Debug",        { fg = c.brown })
hi("Underlined",   { fg = c.purple, underline = true })
hi("Ignore",       { fg = c.fg_gutter })
hi("Error",        { fg = c.red_bright, bold = true })
hi("Todo",         { fg = c.bg, bg = c.gold, bold = true })

-- ════════════════════════════════════════════════════════════════════
--  Treesitter (@…) — o grande acréscimo moderno
-- ════════════════════════════════════════════════════════════════════
link("@comment", "Comment")
hi("@comment.documentation", { fg = c.teal, italic = true })
hi("@comment.error",   { fg = c.red_bright })
hi("@comment.warning", { fg = c.orange })
hi("@comment.todo",    { fg = c.bg, bg = c.gold, bold = true })
hi("@comment.note",    { fg = c.bg, bg = c.teal, bold = true })

hi("@keyword",            { fg = c.gold })
link("@keyword.function", "@keyword")
link("@keyword.return",   "@keyword")
link("@keyword.operator", "@keyword")
link("@keyword.import",   "PreProc")
link("@conditional", "Conditional")
link("@repeat",      "Repeat")
link("@exception",   "Exception")
link("@label",       "Label")
hi("@operator", { fg = c.fg })

hi("@function",          { fg = c.olive })
link("@function.call",   "@function")
link("@function.method", "@function")
link("@function.method.call", "@function")
hi("@function.builtin",  { fg = c.olive, italic = true })
link("@constructor", "Type")

hi("@variable",          { fg = c.fg })            -- variáveis na cor de leitura
hi("@variable.builtin",  { fg = c.red, italic = true })  -- self, this…
hi("@variable.parameter",{ fg = c.fg, italic = true })
hi("@variable.member",   { fg = c.purple })        -- campos / propriedades
link("@property", "@variable.member")
link("@field",    "@variable.member")

link("@type",          "Type")
hi("@type.builtin",    { fg = c.green, italic = true })
link("@type.definition", "Typedef")
link("@module",      "Type")
link("@namespace",   "Type")

hi("@string",            { fg = c.red })
hi("@string.escape",     { fg = c.brown })
hi("@string.regexp",     { fg = c.brown })
hi("@string.special",    { fg = c.brown })
link("@character", "Character")
link("@number",  "Number")
link("@boolean", "Boolean")
link("@float",   "Float")

hi("@constant",          { fg = c.red })
hi("@constant.builtin",  { fg = c.orange })
hi("@constant.macro",    { fg = c.blue })

link("@preproc", "PreProc")
link("@include", "Include")
link("@define",  "Define")

hi("@punctuation.delimiter", { fg = c.fg_dim })
hi("@punctuation.bracket",   { fg = c.fg_dim })
hi("@punctuation.special",   { fg = c.brown })

-- Markup (markdown / notas)
hi("@markup.heading",        { fg = c.aqua, bold = true })
hi("@markup.heading.1.markdown", { fg = c.gold, bold = true })
hi("@markup.heading.2.markdown", { fg = c.green, bold = true })
hi("@markup.heading.3.markdown", { fg = c.aqua, bold = true })
hi("@markup.heading.4.markdown", { fg = c.teal, bold = true })
hi("@markup.heading.5.markdown", { fg = c.blue, bold = true })
hi("@markup.heading.6.markdown", { fg = c.purple, bold = true })
hi("@markup.strong",         { fg = c.fg, bold = true })
hi("@markup.italic",         { fg = c.fg, italic = true })
hi("@markup.strikethrough",  { fg = c.fg_dim, strikethrough = true })
hi("@markup.raw",            { fg = c.brown })           -- código inline
hi("@markup.raw.block",      { fg = c.fg })
hi("@markup.link",           { fg = c.royal, underline = true })
hi("@markup.link.label",     { fg = c.teal })
hi("@markup.list",           { fg = c.gold })
hi("@markup.quote",          { fg = c.fg_dim, italic = true })

hi("@tag",            { fg = c.gold })
hi("@tag.attribute",  { fg = c.olive })
hi("@tag.delimiter",  { fg = c.fg_dim })

hi("@diff.plus",  { fg = c.green })
hi("@diff.minus", { fg = c.red })
hi("@diff.delta", { fg = c.blue })

-- ════════════════════════════════════════════════════════════════════
--  Tokens semânticos de LSP — herdam dos grupos @… acima
-- ════════════════════════════════════════════════════════════════════
link("@lsp.type.class",         "@type")
link("@lsp.type.enum",          "@type")
link("@lsp.type.interface",     "@type")
link("@lsp.type.struct",        "@type")
link("@lsp.type.typeParameter", "@type")
link("@lsp.type.namespace",     "@namespace")
link("@lsp.type.function",      "@function")
link("@lsp.type.method",        "@function")
link("@lsp.type.variable",      "@variable")
link("@lsp.type.parameter",     "@variable.parameter")
link("@lsp.type.property",      "@property")
link("@lsp.type.enumMember",    "@constant")
link("@lsp.type.keyword",       "@keyword")
link("@lsp.type.string",        "@string")
link("@lsp.type.number",        "@number")
link("@lsp.type.comment",       "@comment")
link("@lsp.type.macro",         "@constant.macro")
link("@lsp.type.decorator",     "@function.builtin")

-- Referências do símbolo sob o cursor
hi("LspReferenceText",  { bg = c.fg_faint })
hi("LspReferenceRead",  { bg = c.fg_faint })
hi("LspReferenceWrite", { bg = c.fg_faint, underline = true })
hi("LspSignatureActiveParameter", { fg = c.goldenrod, bold = true })
hi("LspInlayHint",      { fg = c.fg_gutter, bg = c.bg_cursor, italic = true })

-- ════════════════════════════════════════════════════════════════════
--  Diagnostics (também não existiam em 2002)
-- ════════════════════════════════════════════════════════════════════
hi("DiagnosticError", { fg = c.red_bright })
hi("DiagnosticWarn",  { fg = c.gold })
hi("DiagnosticInfo",  { fg = c.blue })
hi("DiagnosticHint",  { fg = c.teal })
hi("DiagnosticOk",    { fg = c.green })
hi("DiagnosticUnderlineError", { undercurl = true, sp = c.red_bright })
hi("DiagnosticUnderlineWarn",  { undercurl = true, sp = c.gold })
hi("DiagnosticUnderlineInfo",  { undercurl = true, sp = c.blue })
hi("DiagnosticUnderlineHint",  { undercurl = true, sp = c.teal })
hi("DiagnosticVirtualTextError", { fg = c.red_bright, bg = "#1c0e0c" })
hi("DiagnosticVirtualTextWarn",  { fg = c.gold,       bg = "#1a1606" })
hi("DiagnosticVirtualTextInfo",  { fg = c.blue,       bg = "#0c1320" })
hi("DiagnosticVirtualTextHint",  { fg = c.teal,       bg = "#0a1717" })

-- ════════════════════════════════════════════════════════════════════
--  Diff / Git
-- ════════════════════════════════════════════════════════════════════
hi("DiffAdd",    { bg = c.diff_add })
hi("DiffChange", { bg = c.diff_change })
hi("DiffDelete", { fg = c.red, bg = c.diff_delete })
hi("DiffText",   { bg = c.diff_text })
hi("diffAdded",   { fg = c.green })
hi("diffRemoved", { fg = c.red })
hi("diffChanged", { fg = c.blue })

-- gitsigns
hi("GitSignsAdd",    { fg = c.green })
hi("GitSignsChange", { fg = c.blue })
hi("GitSignsDelete", { fg = c.red })
link("GitSignsAddNr",    "GitSignsAdd")
link("GitSignsChangeNr", "GitSignsChange")
link("GitSignsDeleteNr", "GitSignsDelete")

-- ════════════════════════════════════════════════════════════════════
--  Plugins do setup
-- ════════════════════════════════════════════════════════════════════
-- blink.cmp
link("BlinkCmpMenu",          "Pmenu")
link("BlinkCmpMenuBorder",    "FloatBorder")
link("BlinkCmpMenuSelection", "PmenuSel")
link("BlinkCmpLabel",         "Pmenu")
hi("BlinkCmpLabelMatch",      { fg = c.gold, bold = true })   -- caracteres do match em destaque
link("BlinkCmpDoc",           "NormalFloat")
link("BlinkCmpDocBorder",     "FloatBorder")
link("BlinkCmpSignatureHelp", "NormalFloat")
hi("BlinkCmpKind",            { fg = c.olive })

-- which-key
hi("WhichKey",          { fg = c.gold })
hi("WhichKeyGroup",     { fg = c.blue })
hi("WhichKeyDesc",      { fg = c.fg })
hi("WhichKeySeparator", { fg = c.fg_dim })
link("WhichKeyFloat",   "NormalFloat")
link("WhichKeyBorder",  "FloatBorder")

-- fzf-lua
link("FzfLuaNormal",       "NormalFloat")
link("FzfLuaBorder",       "FloatBorder")
hi("FzfLuaTitle",          { fg = c.gold, bold = true })
hi("FzfLuaHeaderText",     { fg = c.teal })
hi("FzfLuaPathColNr",      { fg = c.fg_dim })
hi("FzfLuaBufNr",          { fg = c.olive })

-- oil
hi("OilDir",     { fg = c.royal, bold = true })
link("OilDirIcon", "OilDir")
hi("OilFile",    { fg = c.fg })
hi("OilCreate",  { fg = c.green })
hi("OilDelete",  { fg = c.red })
hi("OilMove",    { fg = c.gold })
hi("OilCopy",    { fg = c.blue })
hi("OilChange",  { fg = c.orange })

-- indent-blankline (ibl)
hi("IblIndent",  { fg = c.fg_faint })
hi("IblScope",   { fg = c.fg_gutter })

-- Copilot (ghost text — bem apagado, para não competir com o código)
hi("CopilotSuggestion", { fg = "#5a5a52", italic = true })
hi("CopilotAnnotation", { fg = "#5a5a52", italic = true })

-- markview (cabeçalhos e código nas notas; o resto o plugin gera sozinho)
hi("MarkviewHeading1", { fg = c.gold,  bold = true })
hi("MarkviewHeading2", { fg = c.green, bold = true })
hi("MarkviewHeading3", { fg = c.aqua,  bold = true })
hi("MarkviewHeading4", { fg = c.teal,  bold = true })
hi("MarkviewHeading5", { fg = c.blue,  bold = true })
hi("MarkviewHeading6", { fg = c.purple, bold = true })
hi("MarkviewCode",        { bg = c.bg_float })
hi("MarkviewInlineCode",  { fg = c.brown, bg = c.bg_float })
hi("MarkviewBlockQuote",  { fg = c.fg_dim, italic = true })

-- ── Spell ──
hi("SpellBad",   { undercurl = true, sp = c.red_bright })
hi("SpellCap",   { undercurl = true, sp = c.gold })
hi("SpellRare",  { undercurl = true, sp = c.purple })
hi("SpellLocal", { undercurl = true, sp = c.teal })
