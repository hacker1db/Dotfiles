return {
    {
        "nvim-treesitter/nvim-treesitter",
        branch = "main",
        event = { "BufReadPre", "BufNewFile" },
        build = ":TSUpdate",
        config = function(plugin)
            local ts = require("nvim-treesitter")
            ts.setup()
            vim.opt.rtp:remove(plugin.dir)
            -- Append runtime/ so queries are found without prepending the plugin root,
            -- which would override user queries in ~/.config/nvim (e.g. queries/vim/highlights.scm)
            vim.opt.rtp:append(plugin.dir .. "/runtime")

            -- The main branch no longer installs parsers or enables features from setup()
            ts.install({
                "bash", "c_sharp", "css", "html", "javascript", "json", "lua", "markdown",
                "markdown_inline", "python", "rust", "tsx", "typescript", "vim", "yaml", "astro",
            })

            local available = {}
            for _, lang in ipairs(ts.get_available()) do
                available[lang] = true
            end

            local function start(buf, lang)
                if not vim.api.nvim_buf_is_valid(buf) or not pcall(vim.treesitter.start, buf, lang) then
                    return
                end
                vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
            end

            local function attach(buf, filetype)
                local lang = vim.treesitter.language.get_lang(filetype)
                if not lang or not available[lang] then
                    return
                end
                if vim.list_contains(ts.get_installed("parsers"), lang) then
                    start(buf, lang)
                else
                    -- auto_install equivalent: install the missing parser, then start
                    ts.install({ lang }):await(function(err)
                        if not err then
                            vim.schedule(function() start(buf, lang) end)
                        end
                    end)
                end
            end

            vim.api.nvim_create_autocmd("FileType", {
                group = vim.api.nvim_create_augroup("TreesitterStart", { clear = true }),
                callback = function(ev)
                    attach(ev.buf, ev.match)
                end,
            })
            -- Buffers whose FileType fired before this plugin loaded
            for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype ~= "" then
                    attach(buf, vim.bo[buf].filetype)
                end
            end
        end,
    },
    {
        "nvim-treesitter/nvim-treesitter-context",
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            require("treesitter-context").setup({
                enable = true,
                multiwindow = false,
                max_lines = 0,
                min_window_height = 0,
                line_numbers = true,
                multiline_threshold = 20,
                trim_scope = "outer",
                mode = "cursor",
                separator = nil,
                zindex = 20,
                on_attach = nil,
            })
        end,
    },
    {
        "windwp/nvim-ts-autotag",
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            require("nvim-ts-autotag").setup()
        end,
    },
    {
        "nvim-treesitter/nvim-treesitter-textobjects",
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            require("nvim-treesitter-textobjects").setup({
                select = { lookahead = true },
            })

            -- The main branch does not create mappings from config tables
            local ts_select = require("nvim-treesitter-textobjects.select")
            local swap = require("nvim-treesitter-textobjects.swap")
            for lhs, query in pairs({
                ["af"] = "@function.outer",
                ["if"] = "@function.inner",
                ["ac"] = "@class.outer",
                ["ic"] = "@class.inner",
            }) do
                vim.keymap.set({ "x", "o" }, lhs, function()
                    ts_select.select_textobject(query, "textobjects")
                end, { desc = "Select " .. query })
            end
            vim.keymap.set("n", "<leader>a", function()
                swap.swap_next("@parameter.inner")
            end, { desc = "Swap next parameter" })
            vim.keymap.set("n", "<leader>A", function()
                swap.swap_previous("@parameter.inner")
            end, { desc = "Swap previous parameter" })
        end,
    },
    { "JoosepAlviste/nvim-ts-context-commentstring", lazy = true },
}
