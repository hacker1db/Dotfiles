-- Colors are now loaded via core.colors and applied in plugins/ui/colorscheme.lua
-- This file is kept for backwards compatibility but delegates to the new system
local c = require("core.colors").colors
local theme = "eldritch"
pcall(vim.cmd, "colorscheme " .. theme)
