local icons = {
    -- system icons
    linux = " ",
    macos = " ",
    windows = " ",
    -- diagnostic icons
    bug = "",
    -- error = "",
    error = " ",
    warning = " ",
    info = " ",
    -- hint = "",
    hint = "󰌶 ",
    lsp = " ",
    -- lsp = " ",
    line = "󰍜 ",
    -- git icons
    git = "",
    conflict = "",
    unstaged = "● ",
    staged = "✓ ",
    unmerged = " ",
    renamed = "➜ ",
    untracked = " ",
    -- deleted = " ",
    ignored = "◌ ",
    modified = "● ",
    deleted = " ",
    added = " ",
    -- file icons
    arrow_closed = " ",
    arrow_open = " ",
    default = " ",
    open = " ",
    empty = " ",
    empty_open = " ",
    -- symlink = "",
    symlink_open = " ",
    file = " ",
    symlink = " ",
    file_readonly = " ",
    file_modified = " ",
    -- misc
    devil = " ",
    bsd = " ",
    ghost = " ",
}

return {
    -- fast colorizer for showing hex colors
    {
        "nvim-lualine/lualine.nvim",
        enabled = true,
        event = "VeryLazy",
        opts = function(plugin)
            if plugin.override then
                require("lazyvim.util").deprecate("lualine.override", "lualine.opts")
            end

            local diagnostics = {
                "diagnostics",
                sources = { "nvim_diagnostic" },
                sections = { "error", "warn", "info", "hint" },
                symbols = {
                    error = icons.bug .. " ",
                    hint = icons.hint,
                    info = icons.info,
                    warn = icons.warning,
                },
                icon = icons.lsp,
                colored = true,
                update_in_insert = false,
                always_visible = false,
            }

            local diff = {
                "diff",
                symbols = {
                    added = icons.added,
                    untracked = icons.added,
                    modified = icons.modified,
                    removed = icons.deleted,
                },
                icon = icons.git,
                colored = true,
                always_visible = false,
                source = function()
                    local gitsigns = vim.b.gitsigns_status_dict
                    if gitsigns then
                        return {
                            added = gitsigns.added,
                            modified = gitsigns.changed,
                            removed = gitsigns.removed,
                        }
                    end
                end,
            }

            return {
                options = {
                    theme = "auto",
                    globalstatus = true,
                    component_separators = { left = "", right = "" },
                    disabled_filetypes = { statusline = { "dashboard", "lazy", "alpha" } },
                },
                sections = {
                    lualine_a = {},
                    lualine_b = {},
                    lualine_c = { diff, diagnostics },
                    lualine_x = {},
                    lualine_y = {},
                    lualine_z = {},
                },
            }
        end,
    },
    {
        "NvChad/nvim-colorizer.lua",
        opts = {
            filetypes = { "*" },
            user_default_options = {
                mode = "background",
                tailwind = true,
                RGB = true,
                RRGGBB = true,
                names = true,
                RRGGBBAA = true,
                rgb_fn = true,
                hsl_fn = true,
                css = true,
                css_fn = true,
            },
        },
    },
    -- Floating statuslines. This is used to shwo buffer names in splits
    { "b0o/incline.nvim", opts = { hide = { cursorline = false, focused_win = false, only_win = true } } },
},
-- Prettier notifications
{
    "rcarriga/nvim-notify",
    keys = {
        {
            "<leader>un",
            function()
                require("notify").dismiss({ silent = true, pending = true })
            end,
            desc = "Dismiss all Notifications",
        },
    },
    opts = {
        timeout = 3000,
        max_height = function()
            return math.floor(vim.o.lines * 0.75)
        end,
        max_width = function()
            return math.floor(vim.o.columns * 0.75)
        end,
        background_colour = "#1e222a",
        render = "minimal",
    },
    init = function()
        local banned_messages = { "No information available" }
        vim.notify = function(msg, ...)
            for _, banned in ipairs(banned_messages) do
                if msg == banned then
                    return
                end
            end
            return require("notify")(msg, ...)
        end
    end,
},
-- Make folds look Prettier
{
    "kevinhwang91/nvim-ufo",
    dependencies = {
        "kevinhwang91/promise-async",
    },
    opts = {
        fold_virt_text_handler = function(virtText, lnum, endLnum, width, truncate)
            local newVirtText = {}
            local suffix = ("   %d "):format(endLnum - lnum)
            local sufWidth = vim.fn.strdisplaywidth(suffix)
            local targetWidth = width - sufWidth
            local curWidth = 0

            for _, chunk in ipairs(virtText) do
                local chunkText = chunk[1]
                local chunkWidth = vim.fn.strdisplaywidth(chunkText)
                if targetWidth > curWidth + chunkWidth then
                    table.insert(newVirtText, chunk)
                else
                    chunkText = truncate(chunkText, targetWidth - curWidth)
                    local hlGroup = chunk[2]
                    table.insert(newVirtText, { chunkText, hlGroup })
                    chunkWidth = vim.fn.strdisplaywidth(chunkText)
                    -- str width returned from truncate() may less than 2nd argument, need padding
                    if curWidth + chunkWidth < targetWidth then
                        suffix = suffix .. (" "):rep(targetWidth - curWidth - chunkWidth)
                    end
                    break
                end
                curWidth = curWidth + chunkWidth
            end

            table.insert(newVirtText, { suffix, "MoreMsg" })

            return newVirtText
        end,
        close_fold_kinds = { "imports" },
    },
}
