return {

  
    "nvim-treesitter/nvim-treesitter",
    event = { "BufReadPre", "BufNewFile" },
    build = ":TSUpdate",
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
      "windwp/nvim-ts-autotag",
    },
 config = function()
      local treesitter = require("nvim-treesitter.configs")
      local comment = require("ts_context_commentstring").setup{}

    treesitter.setup({
ensure_installed = {
            "bash",
            "css",
            "html",
            "javascript",
            "lua",
            "python",
            "rust",
            "typescript",
            "vim",
            "tsx",
            "yaml",
            "json",
            "python",
            "c_sharp",
            "markdown",
            "astro",

 -- vim.g.skip_ts_context_commentstring_module = true





        },
        autotag = {
            enable = true,
        },
        auto_install = true, -- auto install above language parsers
        highlight = {
            enable = true,
            use_languagetree = true,
        },
             
        indent = { enable = true },
        rainbow = {
            enable = true,
            extended_mode = true,
            max_file_lines = 1000,
        },
        textobjects = {
            select = {
                enable = true,
                lookahead = true, -- automatically jump forward to matching textobj
                keymaps = {
                    ["af"] = "@function.outer",
                    ["if"] = "@function.inner",
                    ["ac"] = "@class.outer",
                    ["ic"] = "@class.inner",
                },
            },
            swap = {
                enable = true,
                swap_next = {
                    ["<leader>a"] = "@parameter.inner",
                },
                swap_previous = {
                    ["<leader>A"] = "@parameter.inner",
                },
            },
        },
        playground = {
            enable = true,
            disable = {},
            updatetime = 25,
            persist_queries = false,
            keybindings = {
                toggle_query_editor = "o",
                toggle_hl_groups = "i",
                toggle_injected_languages = "t",
                toggle_anonymous_nodes = "a",
                toggle_language_display = "I",
                focus_language = "f",
                unfocus_language = "F",
                update = "R",
                goto_node = "<cr>",
                show_help = "?",

            }

        }
    })
end 
} 
