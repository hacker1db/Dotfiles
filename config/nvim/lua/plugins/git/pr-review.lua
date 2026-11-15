return {
  name = "pr-review",
  dir = vim.fn.stdpath("config"),
  virtual = true,
  dependencies = { "folke/snacks.nvim", "pwntester/octo.nvim" },
  cmd = { "PrDashboard", "PrTiers", "PrAgent", "PrFindings", "PrOverview" },
  keys = {
    { "<leader>pp", "<cmd>PrDashboard<cr>", desc = "PR dashboard" },
    { "<leader>po", "<cmd>PrOverview<cr>", desc = "PR overview" },
    { "<leader>pt", "<cmd>PrTiers<cr>", desc = "PR files by tier" },
    { "<leader>pa", "<cmd>PrAgent<cr>", desc = "PR agent review" },
    { "<leader>pv", "<cmd>PrFindings<cr>", desc = "PR agent findings" },
    { "<leader>pr", "<cmd>Octo review start<cr>", desc = "PR start Octo review" },
    { "<leader>pR", "<cmd>Octo review resume<cr>", desc = "PR resume Octo review" },
    { "<leader>ps", "<cmd>Octo review submit<cr>", desc = "PR submit Octo review" },
  },
  config = function()
    require("pr_review").setup()
  end,
}
