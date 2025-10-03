return {
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    opts = {
      messages = { enabled = false },
      notify = { enabled = false },
      lsp = {
        progress = { enabled = false },
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
        },
      },
      presets = {
        bottom_search = false,
        long_message_to_split = false,
        inc_rename = false,
        lsp_doc_border = true,
      },
      views = {
        cmdline_popup = {
          border = { style = "rounded" },
          position = { row = 10, col = "50%" },
          size = { width = 60, height = "auto" },
        },
        popupmenu = {
          relative = "editor",
          position = { row = 13, col = "50%" },
          size = { width = 60, height = 10 },
          border = { style = "rounded", padding = { 0, 1 } },
          win_options = { winhighlight = { Normal = "Normal", FloatBorder = "DiagnosticInfo" } },
        },
      },
    },
    dependencies = { "MunifTanjim/nui.nvim" },
  },
}
