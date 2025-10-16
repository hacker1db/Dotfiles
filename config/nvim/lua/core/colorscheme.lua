local theme_file = vim.fn.stdpath("config") .. "/../theme/current"
local theme = "eldritch"
local f = io.open(theme_file, "r")
if f then
  local line = f:read("*l")
  f:close()
  if line and #line > 0 then theme = line end
end
pcall(vim.cmd, "colorscheme " .. theme)
