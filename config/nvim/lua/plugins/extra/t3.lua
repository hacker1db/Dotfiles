-- T3 Code threads from Neovim (lua/t3). CLI: opts.cmd, else $T3_CLI, else "t3".
return {
  dir = vim.fn.stdpath("config") .. "/lua/t3",
  name = "t3",
  cmd = { "T3Start", "T3Send", "T3Steer", "T3Stop", "T3Show", "T3Threads", "T3Providers" },
  keys = {
    { "<leader>Tn", "<cmd>T3Start<cr>", desc = "T3 start thread" },
    { "<leader>Tn", ":T3Start<cr>", mode = "x", desc = "T3 start thread with selection" },
    { "<leader>TN", "<cmd>T3Start!<cr>", desc = "T3 start thread in new worktree" },
    { "<leader>Ts", "<cmd>T3Send<cr>", desc = "T3 send to last thread" },
    { "<leader>Ts", ":T3Send<cr>", mode = "x", desc = "T3 send selection to last thread" },
    { "<leader>TS", "<cmd>T3Send!<cr>", desc = "T3 send to picked thread" },
    { "<leader>Te", "<cmd>T3Steer<cr>", desc = "T3 steer last thread" },
    { "<leader>Te", ":T3Steer<cr>", mode = "x", desc = "T3 steer last thread with selection" },
    { "<leader>TE", "<cmd>T3Steer!<cr>", desc = "T3 steer picked thread" },
    { "<leader>Tx", "<cmd>T3Stop<cr>", desc = "T3 stop last thread" },
    { "<leader>TX", "<cmd>T3Stop!<cr>", desc = "T3 stop picked thread" },
    { "<leader>To", "<cmd>T3Show<cr>", desc = "T3 show last thread" },
    { "<leader>TO", "<cmd>T3Show!<cr>", desc = "T3 show picked thread" },
    { "<leader>Tt", "<cmd>T3Threads<cr>", desc = "T3 threads (this project)" },
    { "<leader>TT", "<cmd>T3Threads!<cr>", desc = "T3 threads (pick project)" },
    { "<leader>Tp", "<cmd>T3Providers<cr>", desc = "T3 project providers" },
  },
  opts = {},
  config = function(_, opts)
    require("t3").setup(opts)
  end,
}
