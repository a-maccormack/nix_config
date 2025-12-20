local telescope = require("telescope")
local builtin = require("telescope.builtin")

telescope.setup({
	defaults = {
		layout_strategy = "horizontal",
		layout_config = {
			horizontal = {
				preview_width = 0.55,
				preview_cutoff = 120,
			},
			width = 0.87,
			height = 0.80,
		},
		file_previewer = require("telescope.previewers").vim_buffer_cat.new,
		grep_previewer = require("telescope.previewers").vim_buffer_vimgrep.new,
	},
	pickers = {
		find_files = {
			previewer = true,
		},
		grep_string = {
			previewer = true,
		},
		live_grep = {
			previewer = true,
		},
	},
})

-- Keymaps
vim.keymap.set("n", "<leader>pf", builtin.find_files, { desc = "Find files" })
vim.keymap.set("n", "<C-p>", builtin.git_files, { desc = "Git files" })
vim.keymap.set("n", "<leader>ps", function()
	builtin.grep_string({ search = vim.fn.input("Grep > ") })
end, { desc = "Grep string" })
vim.keymap.set("n", "<leader>lg", builtin.live_grep, { desc = "Live grep" })
vim.keymap.set("n", "gd", builtin.lsp_definitions, { noremap = true, silent = true, desc = "Go to definition" })
