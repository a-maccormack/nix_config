---
-- LSP Configuration (Neovim 0.11+ native API)
---

local capabilities = require("cmp_nvim_lsp").default_capabilities()

-- Handle LSP messages quietly (prevents "Press ENTER" interruptions)
vim.lsp.handlers["window/showMessage"] = function(_, result, ctx)
	local client = vim.lsp.get_client_by_id(ctx.client_id)
	local client_name = client and client.name or "LSP"
	local message = result.message

	-- Map LSP MessageType: 1=Error, 2=Warning, 3=Info, 4=Log
	local level = ({ vim.log.levels.ERROR, vim.log.levels.WARN, vim.log.levels.INFO, vim.log.levels.DEBUG })[result.type]
		or vim.log.levels.INFO

	vim.notify(string.format("[%s] %s", client_name, message), level)
end

-- LSP attach keybindings via autocmd
vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(args)
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		local bufnr = args.buf
		local opts = { buffer = bufnr, silent = true }

		if client.name == "ts_ls" then
			client.server_capabilities.documentFormattingProvider = false
			client.server_capabilities.documentRangeFormattingProvider = false
		end

		if client.name == "elixirls" then
			client.server_capabilities.documentFormattingProvider = true
			vim.api.nvim_create_autocmd("BufWritePre", {
				buffer = bufnr,
				callback = function()
					local ok, err = pcall(vim.lsp.buf.format, { async = false, timeout_ms = 3000 })
					if not ok then
						vim.notify("[elixirls] Format failed: " .. tostring(err), vim.log.levels.WARN)
					end
				end,
			})
		end

		vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
		vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
		vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
		vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
		vim.keymap.set("n", "gr", require("telescope.builtin").lsp_references, opts)
		vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
		vim.keymap.set("n", "<leader>f", function()
			require("conform").format({ async = true, lsp_fallback = true })
		end, opts)

		vim.keymap.set("n", "<leader>oi", function()
			vim.lsp.buf.code_action({
				context = { only = { "source.organizeImports", "source.fixAll" } },
				apply = true,
			})
		end, opts)
	end,
})

vim.diagnostic.config({
	virtual_text = false,
	virtual_lines = true,
	signs = true,
	underline = true,
})

-- LSP server configurations using vim.lsp.config (Neovim 0.11+)
vim.lsp.config.ruff = {
	cmd = { "ruff", "server" },
	filetypes = { "python" },
	root_markers = { "pyproject.toml", "ruff.toml", ".ruff.toml", "setup.py", "setup.cfg", ".git" },
	capabilities = capabilities,
}

vim.lsp.config.pyright = {
	cmd = { "pyright-langserver", "--stdio" },
	filetypes = { "python" },
	root_markers = { "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", "pyrightconfig.json", ".git" },
	capabilities = capabilities,
}

vim.lsp.config.lua_ls = {
	cmd = { "lua-language-server" },
	filetypes = { "lua" },
	root_markers = { ".luarc.json", ".luarc.jsonc", ".luacheckrc", ".stylua.toml", "stylua.toml", "selene.toml", "selene.yml", ".git" },
	capabilities = capabilities,
	settings = {
		Lua = {
			runtime = { version = "LuaJIT" },
			diagnostics = { globals = { "vim" } },
			workspace = {
				library = vim.api.nvim_get_runtime_file("", true),
				checkThirdParty = false,
			},
			telemetry = { enable = false },
		},
	},
}

vim.lsp.config.rust_analyzer = {
	cmd = { "rust-analyzer" },
	filetypes = { "rust" },
	root_markers = { "Cargo.toml", "rust-project.json", ".git" },
	capabilities = capabilities,
}

vim.lsp.config.elixirls = {
	cmd = { vim.fn.expand("~/.local/share/elixir-ls/language_server.sh") },
	filetypes = { "elixir", "eelixir", "heex", "surface" },
	root_markers = { "mix.exs", ".git" },
	capabilities = capabilities,
	settings = {
		elixirLS = {
			dialyzerEnabled = true,
			fetchDeps = false,
			suggestSpecs = true,
		},
	},
}

vim.lsp.config.terraformls = {
	cmd = { "terraform-ls", "serve" },
	filetypes = { "terraform", "terraform-vars", "hcl" },
	root_markers = { ".terraform", ".git" },
	capabilities = capabilities,
}

vim.lsp.config.ts_ls = {
	cmd = { "typescript-language-server", "--stdio" },
	filetypes = { "javascript", "javascriptreact", "javascript.jsx", "typescript", "typescriptreact", "typescript.tsx" },
	root_markers = { "tsconfig.json", "jsconfig.json", "package.json", ".git" },
	capabilities = capabilities,
}

vim.lsp.config.nil_ls = {
	cmd = { "nil" },
	filetypes = { "nix" },
	root_markers = { "flake.nix", ".git" },
	capabilities = capabilities,
	settings = {
		["nil"] = {
			formatting = {
				command = { "nixpkgs-fmt" },
			},
			nix = {
				flake = {
					autoArchive = true,
				},
			},
		},
	},
}

-- Enable all configured LSP servers
vim.lsp.enable({ "ruff", "pyright", "lua_ls", "rust_analyzer", "elixirls", "terraformls", "ts_ls", "nil_ls" })

-- Conform formatter setup
require("conform").setup({
	formatters_by_ft = {
		javascript = { "prettier" },
		javascriptreact = { "prettier" },
		typescript = { "prettier" },
		typescriptreact = { "prettier" },
		json = { "prettier" },
		html = { "prettier" },
		css = { "prettier" },
		yaml = { "prettier" },
		markdown = { "prettier" },
		python = { "ruff_organize_imports", "ruff_format" },
		terraform = { "terraform_fmt" },
		hcl = { "terraform_fmt" },
		elixir = { "mix" },
		heex = { "mix" },
		lua = { "stylua" },
		nix = { "nixpkgs_fmt" },
	},
	format_on_save = {
		lsp_fallback = true,
		timeout_ms = 1500,
	},
})

-- Auto-format and organize imports
local aug = vim.api.nvim_create_augroup("FormatAndImports", { clear = true })

vim.api.nvim_create_autocmd("BufWritePre", {
	group = aug,
	pattern = { "*.js", "*.jsx", "*.ts", "*.tsx" },
	callback = function(args)
		pcall(vim.lsp.buf.code_action, {
			context = { only = { "source.organizeImports" } },
			apply = true,
		})
		require("conform").format({
			bufnr = args.buf,
			async = false,
			lsp_fallback = true,
		})
	end,
})

vim.api.nvim_create_autocmd("BufWritePre", {
	group = aug,
	pattern = { "*.py" },
	callback = function(args)
		require("conform").format({
			bufnr = args.buf,
			async = false,
			lsp_fallback = true,
			formatters = { "ruff_organize_imports", "ruff_format" },
		})
	end,
})
