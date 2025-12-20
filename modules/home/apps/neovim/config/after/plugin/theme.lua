local ok, github_theme = pcall(require, "github-theme")
if ok then
	github_theme.setup({
		-- ...
	})
end

-- Set colorscheme
local color = "github_dark_default"
vim.cmd("colorscheme " .. color)

vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
