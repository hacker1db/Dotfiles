return {
    "nvimdev/lspsaga.nvim",
    event = "LspAttach",
    dependencies = {
        "nvim-treesitter/nvim-treesitter",
        "echasnovski/mini.icons",
    },
    opts = {
        symbol_in_winbar = {
            enable = true,
        },
        lightbulb = {
            enable = true,
            sign = true,
            virtual_text = false,
        },
        code_action = {
            show_server_name = true,
            extend_gitsigns = false,
        },
        rename = {
            in_select = false,
            auto_save = true,
        },
        hover = {
            open_cmd = "!open",
        },
        outline = {
            layout = "float",
        },
    },
    keys = {
        { "<leader>ca", "<cmd>Lspsaga code_action<CR>",          mode = { "n", "v" }, desc = "Code action (Lspsaga)" },
        {
            "<leader>cr",
            function()
                local line = vim.api.nvim_get_current_line()
                local col = vim.api.nvim_win_get_cursor(0)[2] + 1 -- 1-indexed
                -- Check if cursor is inside a [[wiki link]]
                local pos = 1
                while true do
                    local s, e = line:find("%[%[(.-)%]%]", pos)
                    if not s then break end
                    if col >= s and col <= e then
                        local link_name = line:sub(s + 2, e - 2):match("^([^|#]+)")
                        vim.ui.input({ prompt = "Rename note: ", default = link_name }, function(new_name)
                            if not new_name or new_name == "" or new_name == link_name then return end
                            local vault = vim.fn.expand("~/notes/SecondBrain")
                            -- Use vim.fn.globpath to find the file (handles spaces safely, no shell)
                            local matches = vim.fn.globpath(vault, "**/" .. link_name .. ".md", false, true)
                            if #matches == 0 then
                                vim.notify("File not found: " .. link_name .. ".md", vim.log.levels.ERROR)
                                return
                            end
                            local old_path = matches[1]
                            local new_path = vim.fn.fnamemodify(old_path, ":h") .. "/" .. new_name .. ".md"
                            local ok, err = os.rename(old_path, new_path)
                            if not ok then
                                vim.notify("Rename failed: " .. tostring(err), vim.log.levels.ERROR)
                                return
                            end
                            -- Update all references across the vault using rg + sed
                            local esc_vault = vim.fn.shellescape(vault)
                            local updated = 0
                            for _, pat in ipairs({
                                { find = "[[" .. link_name .. "]]", replace = "[[" .. new_name .. "]]" },
                                { find = "[[" .. link_name .. "|",  replace = "[[" .. new_name .. "|" },
                                { find = "[[" .. link_name .. "#",  replace = "[[" .. new_name .. "#" },
                            }) do
                                local rg_cmd = { "rg", "-l", "--fixed-strings", pat.find, vault, "--glob", "*.md" }
                                local files = vim.fn.systemlist(rg_cmd)
                                for _, file in ipairs(files) do
                                    local fh = io.open(file, "r")
                                    if fh then
                                        local content = fh:read("*a")
                                        fh:close()
                                        -- Plain string replace (no patterns)
                                        local new_content, count = content:gsub(vim.pesc(pat.find), pat.replace)
                                        if count > 0 then
                                            local wh = io.open(file, "w")
                                            if wh then
                                                wh:write(new_content)
                                                wh:close()
                                                updated = updated + 1
                                            end
                                        end
                                    end
                                end
                            end
                            -- Update the current buffer in-place so undo works
                            vim.cmd("checktime")
                            -- Store rename info so undo can revert the file rename
                            vim.b._wiki_rename_undo = { old_path = old_path, new_path = new_path,
                                old_name = link_name, new_name = new_name, vault = vault }
                            -- Watch for undo reverting the link text back
                            vim.api.nvim_create_autocmd("TextChanged", {
                                buffer = 0,
                                callback = function()
                                    local info = vim.b._wiki_rename_undo
                                    if not info then return true end
                                    local cur_line = vim.api.nvim_get_current_line()
                                    -- If the old link name reappears, the user undid the rename
                                    if cur_line:find("%[%[" .. vim.pesc(info.old_name) .. "%]%]")
                                        or cur_line:find("%[%[" .. vim.pesc(info.old_name) .. "|")
                                        or cur_line:find("%[%[" .. vim.pesc(info.old_name) .. "#") then
                                        -- Revert file rename
                                        os.rename(info.new_path, info.old_path)
                                        -- Revert references in other files
                                        for _, pat in ipairs({
                                            { find = "[[" .. info.new_name .. "]]", replace = "[[" .. info.old_name .. "]]" },
                                            { find = "[[" .. info.new_name .. "|",  replace = "[[" .. info.old_name .. "|" },
                                            { find = "[[" .. info.new_name .. "#",  replace = "[[" .. info.old_name .. "#" },
                                        }) do
                                            local rg_cmd = { "rg", "-l", "--fixed-strings", pat.find, info.vault, "--glob", "*.md" }
                                            local files = vim.fn.systemlist(rg_cmd)
                                            for _, file in ipairs(files) do
                                                local fh = io.open(file, "r")
                                                if fh then
                                                    local content = fh:read("*a")
                                                    fh:close()
                                                    local new_content = content:gsub(vim.pesc(pat.find), pat.replace)
                                                    if new_content ~= content then
                                                        local wh = io.open(file, "w")
                                                        if wh then wh:write(new_content); wh:close() end
                                                    end
                                                end
                                            end
                                        end
                                        vim.cmd("checktime")
                                        vim.b._wiki_rename_undo = nil
                                        vim.notify("Reverted rename: '" .. info.new_name .. "' → '" .. info.old_name .. "'", vim.log.levels.INFO)
                                        return true -- remove autocmd
                                    end
                                end,
                            })
                            vim.notify(string.format("Renamed '%s' → '%s' (%d files updated)",
                                link_name, new_name, updated), vim.log.levels.INFO)
                        end)
                        return
                    end
                    pos = e + 1
                end
                -- Not on a wiki link — normal LSP rename
                vim.lsp.buf.rename()
            end,
            desc = "Smart rename (LSP)",
        },
        { "K",          "<cmd>Lspsaga hover_doc<CR>",            desc = "Hover doc (Lspsaga)" },
        { "gp",         "<cmd>Lspsaga peek_definition<CR>",      desc = "Peek definition (Lspsaga)" },
        { "gP",         "<cmd>Lspsaga peek_type_definition<CR>", desc = "Peek type definition (Lspsaga)" },
        { "<leader>cC", vim.lsp.codelens.run,                     desc = "Run codelens (LSP)" },
        { "<leader>lo", "<cmd>Lspsaga outline<CR>",              desc = "Outline (Lspsaga)" },
    },
}
