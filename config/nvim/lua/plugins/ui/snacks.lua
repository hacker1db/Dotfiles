return {
  "folke/snacks.nvim",
  lazy = false,
  priority = 1000,
  opts = function()
    local argc = vim.fn.argc()
    local suppress_dashboard = false
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
      notifier = { enabled = true, timeout = 3000, top_down = true, style = { border = "rounded", zindex = 100, ft = "markdown", wo = { winblend = 5, wrap = false, conceallevel = 2, colorcolumn = "" }, bo = { filetype = "snacks_notif" } } },
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
    local suppress_dashboard = false
    snacks.setup(opts)
    vim.notify = snacks.notifier.notify
    -- save notification via snacks notifier
    vim.api.nvim_create_autocmd("BufWritePost", {
      callback = function(ev)
        local ok, notifier = pcall(require, "snacks.notifier")
        if ok then
          local file = vim.fn.fnamemodify(ev.file or "", ":~:.")
          if file == "" then file = "[No Name]" end
          notifier.notify("Saved " .. file, { level = "info", title = "Write" })
        end
      end,
    })

    -- lsp progress spinner notifications
    vim.api.nvim_create_autocmd("LspProgress", {
      callback = function(ev)
        local spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
        local icon = spinner[math.floor(vim.uv.hrtime() / (1e6 * 80)) % #spinner + 1]
        local val = ev.data.params.value or {}
        if val.kind == "end" then icon = " " end
        local msg = val.message or val.title or "";
        if val.percentage then msg = msg .. string.format(" (%d%%)", val.percentage) end
        if msg == "" then msg = "Working" end
        pcall(vim.notify, msg, "info", {
          id = "lsp_progress",
          title = "LSP Progress",
          icon = icon,
          replace = true,
        })
      end,
    })

    -- dashboard always shown on startup; auto file picker disabled
  end,
}
