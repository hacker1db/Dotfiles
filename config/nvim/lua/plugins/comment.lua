-- import comment plugin safely
local setup, comment = pcall(require, "Comment")
if not setup then
    return
end
local setup, ts_context_commentstring = pcall(require, "ts_context_commentstring")
if not setup then
    return
end

ts_context_commentstring.setup({
    enable_autocmd = false,
    languages = {
        typescript = "// %s",
    },
})

-- enable comment
comment.setup({
    pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
})
