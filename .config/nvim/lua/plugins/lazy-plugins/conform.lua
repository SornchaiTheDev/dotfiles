return { -- Autoformat
	"stevearc/conform.nvim",
	lazy = false,
	keys = {
		{
			"<C-f>",
			function()
				require("conform").format({ async = true, lsp_fallback = true })
			end,
			mode = "",
			desc = "[F]ormat buffer",
		},
	},
	opts = function()
		local web_dev = { { "prettierd", "prettier" } }
		return {
			notify_on_error = false,
			-- format_on_save = function(bufnr)
			-- 	-- Disable "format_on_save lsp_fallback" for languages that don't
			-- 	-- have a well standardized coding style. You can add additional
			-- 	-- languages here or re-enable it for the disabled ones.
			-- 	local disable_filetypes = { c = true, cpp = true }
			-- 	return {
			-- 		timeout_ms = 500,
			-- 		lsp_fallback = not disable_filetypes[vim.bo[bufnr].filetype],
			-- 	}
			-- end,

			formatters_by_ft = {
				lua = { "stylua" },
				python = { "black", "pyright" },
				yaml = { "prettier" },
				-- Conform can also run multiple formatters sequentially
				-- python = { "isort", "black" },
				--
				-- use a sublist to run only the first one that loaded
				javascript = web_dev,
				typescript = web_dev,
				typescriptreact = web_dev,
			},
		}
	end,
}
