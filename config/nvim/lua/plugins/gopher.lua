-- import comment plugin safely
local setup, gopher = pcall(require, "gopher")
if not setup then
    return
end

gopher.setup({
    commands = {
        go = "go",
        gomodifytags = "gomodifytags",
        gotests = "~/go/bin/gotests", -- also you can set custom command path
        impl = "impl",
        iferr = "iferr",
    },
})
