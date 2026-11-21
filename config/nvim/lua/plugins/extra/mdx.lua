-- MDX syntax highlighting through Treesitter (markdown, tsx, typescript parsers).
-- It only defines a filetype, so it loads at startup, as its README suggests.
return {
    "davidmh/mdx.nvim",
    lazy = false,
    dependencies = { "nvim-treesitter/nvim-treesitter" },
}
