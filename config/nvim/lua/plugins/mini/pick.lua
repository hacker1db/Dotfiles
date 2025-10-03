return {
    "echasnovski/mini.pick",
    version = false,
    config = function()
        require("mini.pick").setup({
            mappings = {
                move_down = "<C-j>",
                move_up = "<C-k>",
            },
            window = {
                config = function()
                    local height = math.floor(0.618 * vim.o.lines)
                    local width = math.floor(0.618 * vim.o.columns)
                    return {
                        anchor = "NW",
                        height = height,
                        width = width,
                        row = math.floor(0.5 * (vim.o.lines - height)),
                        col = math.floor(0.5 * (vim.o.columns - width)),
                    }
                end,
            },
        })
    end,
}
