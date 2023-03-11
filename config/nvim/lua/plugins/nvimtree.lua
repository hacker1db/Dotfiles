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
local function open_nvim_tree(data)
	-- buffer is a directory
	local directory = vim.fn.isdirectory(data.file) == 1

	if not directory then
		return
	end

	-- change to the directory
	vim.cmd.cd(data.file)

	-- open the tree
	require("nvim-tree.api").tree.open()
end

nvimtree.setup({
	disable_netrw = false,
	hijack_netrw = true,
	diagnostics = {
		enable = false,
	},
	update_focused_file = {
		enable = true,
		update_cwd = true,
	},
	git = {
		enable = true,
		ignore = false,
	},
	view = {
		width = 40,
		side = "right",
	},
})

vim.api.nvim_create_autocmd("BufEnter", {
	nested = true,
	callback = function()
		if #vim.api.nvim_list_wins() == 1 and require("nvim-tree.utils").is_nvim_tree_buf() then
			vim.cmd("quit")
		end
	end,
})

vim.api.nvim_create_autocmd({ "VimEnter" }, { callback = open_nvim_tree })
