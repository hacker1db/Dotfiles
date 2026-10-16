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

    -- Auto-capitalize markdown heading words on save
    vim.api.nvim_create_autocmd("BufWritePre", {
      buffer = ev.buf,
      callback = function(args)
        local bufnr = args.buf
        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        for i, line in ipairs(lines) do
          local hashes, text = line:match("^(#+)%s+(.*)")
          if hashes and text ~= "" then
            local capitalized = text:gsub("(%a)([%w']*)", function(first, rest)
              return first:upper() .. rest
            end)
            if capitalized ~= text then
              vim.api.nvim_buf_set_lines(bufnr, i - 1, i, false, { hashes .. " " .. capitalized })
            end
          end
        end
      end,
    })

    -- Update/insert TOC using markdown-toc
    vim.keymap.set("n", "<leader>mt", function()
      local path = vim.fn.expand("%:p")
      vim.fn.system('markdown-toc --bullets "-" -i ' .. vim.fn.shellescape(path))
      vim.cmd("edit!")
      vim.cmd("silent write")
      vim.notify("TOC updated", vim.log.levels.INFO)
    end, { buffer = ev.buf, silent = true, desc = "Update markdown TOC" })
  end
})

-- Enable codelens for markdown buffers
local function codelens_supported(bufnr)
  for _, c in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
    if c.server_capabilities and c.server_capabilities.codeLensProvider then
      return true
    end
  end
  return false
end

local function enable_markdown_codelens(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then return end
  if vim.bo[bufnr].buftype ~= "" then return end
  if vim.bo[bufnr].filetype ~= "markdown" then return end
  if not codelens_supported(bufnr) then return end
  vim.lsp.codelens.enable(true, { bufnr = bufnr })
end

vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave", "TextChanged" }, {
  callback = function(args)
    enable_markdown_codelens(args.buf)
  end,
})
