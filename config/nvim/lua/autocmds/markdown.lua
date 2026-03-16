vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function(ev)
    -- Disable inline virtual text for markdownlint (keep gutter signs + underline)
    vim.api.nvim_create_autocmd("DiagnosticChanged", {
      buffer = ev.buf,
      once = true,
      callback = function()
        for name, ns_id in pairs(vim.api.nvim_get_namespaces()) do
          if name:match("lint") then
            vim.diagnostic.config({ virtual_text = false }, ns_id)
          end
        end
      end,
    })

    local opts = { buffer = ev.buf, silent = true, desc = "Insert markdown link" }
    local function insert_link(mode)
      if mode == "v" then
        local save_reg = vim.fn.getreg('"')
        local save_type = vim.fn.getregtype('"')
        vim.cmd("normal! y")
        local sel = vim.fn.getreg('"')
        vim.fn.setreg('"', save_reg, save_type)
        sel = sel:gsub("\n$", "")
        local url = vim.fn.input("URL: ") or ""
        local link = "[" .. sel .. "](" .. url .. ")"
        vim.cmd("normal! gv")
        vim.cmd("normal! c" .. link)
      else
        local text = vim.fn.input("Link text (blank ok): ")
        if text == nil then text = "" end
        local url = vim.fn.input("URL (blank ok): ")
        if url == nil then url = "" end
        local link = "[" .. text .. "](" .. url .. ")"
        vim.api.nvim_put({ link }, "c", true, true)
        if text == "" then
          local row, col = unpack(vim.api.nvim_win_get_cursor(0))
          local target_col = col - (#url + 2)
          if target_col < 1 then target_col = 1 end
          vim.api.nvim_win_set_cursor(0, { row, target_col })
        end
      end
    end
    vim.keymap.set({ "n", "v" }, "<leader>ml", function() insert_link(vim.fn.mode()) end, opts)
    vim.keymap.set({ "n", "v" }, "ml", function() insert_link(vim.fn.mode()) end, opts)
  end
})
