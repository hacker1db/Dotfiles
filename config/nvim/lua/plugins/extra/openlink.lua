return {
  dir = vim.fn.stdpath("config") .. "/lua/openlink",
  name = "openlink",
  keys = {
    { "gx", function() require("openlink").open() end, desc = "Open link under cursor" },
  },
  opts = {
    prefer_obsidian = true,
  },
  config = function(_, opts)
    require("openlink").setup(opts)
  end,
}
