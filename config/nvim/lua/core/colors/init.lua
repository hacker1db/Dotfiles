-- Linkarzu-style color loader
-- Parses active-colorscheme.sh so colors can be shared across apps

local M = {}

local function load_colors()
  local colors = {}
  local script_dir = debug.getinfo(1, "S").source:sub(2):match("(.*/)")
  local color_file = script_dir .. "active-colorscheme.sh"

  local file = io.open(color_file, "r")
  if not file then
    vim.notify("Could not open colorscheme file: " .. color_file, vim.log.levels.WARN)
    return colors
  end

  for line in file:lines() do
    if not line:match("^%s*#") and not line:match("^%s*$") then
      local name, value = line:match("^(%S+)=%s*(.+)")
      if name and value then
        colors[name] = value:gsub('"', "")
      end
    end
  end

  file:close()
  return colors
end

M.colors = load_colors()

function M.get(name)
  return M.colors[name]
end

return M
