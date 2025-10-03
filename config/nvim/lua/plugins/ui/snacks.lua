return {
  "folke/snacks.nvim",
  event = "VeryLazy",
  priority = 1000,
  opts = {
    notifier = { enabled = true, timeout = 3000, top_down = false },
    indent = { enabled = true, char = "┊" },
    scroll = { enabled = true },
    words = { enabled = true },
    bufdelete = { enabled = true },
    zen = { enabled = true },
    terminal = { enabled = true },
    lazygit = { enabled = true },
    statuscolumn = { enabled = false },
    picker = { enabled = false },
    explorer = { enabled = false },
  },
  config = function(_, opts)
    local snacks = require("snacks")
    snacks.setup(opts)
    vim.notify = snacks.notifier.notify
  end,
}
