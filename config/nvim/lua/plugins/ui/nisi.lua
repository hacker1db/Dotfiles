-- Nisi theme — aether.nvim fed the Tokyo Night palette, ported from
-- nicknisi/dotfiles (MIT). Active only when config/theme/current is "nisi";
-- eldritch stays the default (see colorscheme.lua).
return {
  "bjarneo/aether.nvim",
  branch = "v3",
  name = "aether",
  lazy = false,
  priority = 1000,
  cond = function()
    return require("core.theme").current() == "nisi"
  end,
  config = function()
    local opts = { transparent = true }
    local palette = vim.fn.expand("~/.config/theme/nisi/nvim-aether.json")
    if vim.fn.filereadable(palette) == 1 then
      local ok, colors = pcall(vim.json.decode, table.concat(vim.fn.readfile(palette), "\n"))
      if ok and type(colors) == "table" then
        opts.colors = colors
      end
    end
    require("aether").setup(opts)
    vim.cmd.colorscheme("aether")
  end,
}
