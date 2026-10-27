-- Reads the active dotfiles theme name from config/theme/current
-- (symlinked at ~/.config/theme/current by the installer)

local M = {}

function M.current()
  local file = vim.fn.expand("~/.config/theme/current")
  local lines = vim.fn.filereadable(file) == 1 and vim.fn.readfile(file, "", 1) or {}
  local name = (lines[1] or ""):gsub("%s+", "")
  return name ~= "" and name or "eldritch"
end

return M
