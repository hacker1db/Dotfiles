return {
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    opts = {
      presets = {
        bottom_search = false,
        lsp_doc_border = true,
      },
      messages = {
        enabled = true,
        view = "mini",
        view_error = "mini",
        view_warn = "mini",
        view_history = "mini",
        view_search = "mini",
      },
      notify = {
        enabled = true,
        view = "mini",
      },
      lsp = {
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
        },
        message = {
          enabled = true,
          view = "mini",
        },
      },
      views = {
        cmdline_popup = {
          position = {
            row = "40%",
            col = "50%",
          },
        },
        mini = {
          timeout = 5000,
          align = "center",
          position = {
            row = "95%",
            col = "100%",
          },
        },
      },
    },
    dependencies = { "MunifTanjim/nui.nvim" },
  },
}
