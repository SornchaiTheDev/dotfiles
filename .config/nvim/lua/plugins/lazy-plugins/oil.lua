return {
	"stevearc/oil.nvim",
	opts = {},
	config = function()
		require("oil").setup({
			lsp_file_methods = {
				-- Enable or disable LSP file operations
				enabled = true,
				-- Time to wait for LSP file operations to complete before skipping
				timeout_ms = 1000,
				-- Set to true to autosave buffers that are updated with LSP willRenameFiles
				-- Set to "unmodified" to only save unmodified buffers
				autosave_changes = true,
			},
		})
	end,
	-- Optional dependencies
	dependencies = { { "echasnovski/mini.icons", opts = {} } },
	-- dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if prefer nvim-web-devicons
}
