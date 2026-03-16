-- Linkarzu-style highlight overrides
-- Applies markdown heading colors from the shared color palette

local colors = require("core.colors").colors

-- Heading fg/bg pairs: { fg_key, bg_key }
local headings = {
  { "linkarzu_color04", "linkarzu_color18" }, -- H1: purple
  { "linkarzu_color02", "linkarzu_color19" }, -- H2: green
  { "linkarzu_color03", "linkarzu_color20" }, -- H3: cyan
  { "linkarzu_color01", "linkarzu_color21" }, -- H4: pink
  { "linkarzu_color05", "linkarzu_color22" }, -- H5: yellow-green
  { "linkarzu_color08", "linkarzu_color23" }, -- H6: orange
}

for i, pair in ipairs(headings) do
  local fg = colors[pair[1]]
  local bg = colors[pair[2]]
  if fg and bg then
    vim.api.nvim_set_hl(0, "@markup.heading." .. i .. ".markdown", { fg = fg, bg = bg, bold = true })
    vim.api.nvim_set_hl(0, "Headline" .. i .. "Bg", { fg = fg, bg = bg })
    vim.api.nvim_set_hl(0, "Headline" .. i .. "Fg", { fg = fg, bold = true })
  end
end

-- Render-markdown highlights
local codeblock_bg = colors["linkarzu_color07"]
local inline_fg = colors["linkarzu_color10"]
local inline_bg = colors["linkarzu_color02"]
local quote_fg = colors["linkarzu_color12"]

if codeblock_bg then vim.api.nvim_set_hl(0, "RenderMarkdownCode", { bg = codeblock_bg }) end
if inline_fg and inline_bg then vim.api.nvim_set_hl(0, "RenderMarkdownCodeInline", { fg = inline_fg, bg = inline_bg }) end
if quote_fg then vim.api.nvim_set_hl(0, "RenderMarkdownQuote", { fg = quote_fg }) end

-- Markup overrides
local bold_fg = colors["linkarzu_color24"]
local raw_fg = colors["linkarzu_color01"]
if bold_fg then vim.api.nvim_set_hl(0, "@markup.strong", { fg = bold_fg, bold = true }) end
if raw_fg then vim.api.nvim_set_hl(0, "@markup.raw.markdown_inline", { fg = raw_fg }) end
