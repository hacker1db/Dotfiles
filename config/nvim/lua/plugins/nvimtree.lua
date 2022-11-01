local nvimtree = require("nvim-tree")
local view = require("nvim-tree.view")
_G.NvimTreeConfig = {}


function NvimTreeConfig.find_toggle()
  if view.is_visible() then
    view.close()
  else
    vim.cmd("NvimTreeToggle")
  end
end


nvimtree.setup {
  disable_netrw = false,
  hijack_netrw = true,
  diagnostics = {
    enable = false
  },
  update_focused_file = {
    enable = true,
    update_cwd = false
  },
  git = {
    enable = true,
    ignore = false
  },
  view = {
    width = 40,
    side = "left"
  }
}
