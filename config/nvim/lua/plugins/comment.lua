return {
    "numToStr/Comment.nvim",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
        "JoosepAlviste/nvim-ts-context-commentstring",
    },
    config = function()
        -- import comment plugin safely
        local comment = require("Comment")

        local ts_context_commentstring = require("ts_context_commentstring").setup({
            enable_autocmd = false,
        })

        -- enable comment
        comment.setup({
            -- for commenting tsx and jsx files
            pre_hook = ts_context_commentstring.create_pre_hook(),
        })
    end,
}
