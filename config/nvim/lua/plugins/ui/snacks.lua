return {
  "folke/snacks.nvim",
  lazy = false,
  priority = 1000,
  opts = function()
    local suppress_dashboard = (vim.fn.argc() == 1 and vim.fn.isdirectory(vim.fn.argv(0)) == 1)
    local dashboard_sections = {
      {
        section = "header",
        padding = 1,
        text = {
          "                                                     ",
          "  ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗ ",
          "  ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║ ",
          "  ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║ ",
          "  ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║ ",
          "  ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║ ",
          "  ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝ ",
          "                                                     ",
        },
      },
      {
        section = "keys",
        gap = 1,
        keys = {
          { icon = " ", key = "n", desc = "New File", action = function()
              if _G.schedule_close_explorer_next_file then _G.schedule_close_explorer_next_file() end
              vim.cmd("ene")
            end },
          { icon = " ", key = "e", desc = "Explorer", action = function()
              local ok, ex = pcall(require, "snacks.explorer"); if not ok then return end
              for _, win in ipairs(vim.api.nvim_list_wins()) do
                local buf = vim.api.nvim_win_get_buf(win)
                local ft = vim.api.nvim_buf_get_option(buf, "filetype")
                if ft == "snacks_explorer" then pcall(vim.api.nvim_win_close, win, true); return end
              end
              ex.open()
            end },
          { icon = "󰱼 ", key = "f", desc = "Find Files", action = function()
              if _G.schedule_close_explorer_next_file then _G.schedule_close_explorer_next_file() end
              local ok, p = pcall(require, "snacks.picker"); if ok then p.files() end
            end },
          { icon = " ", key = "s", desc = "Search", action = function()
              if _G.schedule_close_explorer_next_file then _G.schedule_close_explorer_next_file() end
              local ok, p = pcall(require, "snacks.picker"); if ok then p.grep() end
            end },
          { icon = " ", key = "q", desc = "Quit", action = function() vim.cmd("qa") end },
        },
      },
      { section = "startup" },
    }

    return {
      notifier = { enabled = true, timeout = 3000, top_down = true },
      indent = { enabled = true, char = "┊" },
      scroll = { enabled = true },
      words = { enabled = true },
      bufdelete = { enabled = true },
      zen = { enabled = true },
      terminal = { enabled = true },
      lazygit = { enabled = true },
      picker = { enabled = true },
      explorer = { enabled = true, layout = { preset = "left", width = 30 } },
      quickfile = { enabled = true },
      image = { enabled = true },
      gitbrowse = { enabled = true },
      statuscolumn = { enabled = true },
      dashboard = {
        enabled = true,
        sections = dashboard_sections,
      },
    }
  end,
  config = function(_, opts)
    local snacks = require("snacks")
    local suppress_dashboard = (vim.fn.argc() == 1 and vim.fn.isdirectory(vim.fn.argv(0)) == 1)
    snacks.setup(opts)
    vim.notify = snacks.notifier.notify
    if suppress_dashboard then
      vim.schedule(function()
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          local buf = vim.api.nvim_win_get_buf(win)
          local ft = vim.api.nvim_buf_get_option(buf, "filetype")
          if ft == "snacks_dashboard" then pcall(vim.api.nvim_win_close, win, true) end
        end
        local ok, picker = pcall(require, "snacks.picker")
        if ok then picker.files() end
      end)
    end
  end,
}
