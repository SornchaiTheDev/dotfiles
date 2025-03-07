return {
	"nvimdev/dashboard-nvim",
	event = "VimEnter",
	config = function()
		require("dashboard").setup({
			config = {
				header = require("plugins.decoration.dashboard-header"),
			},
		})
	end,
	dependencies = { { "nvim-tree/nvim-web-devicons" } },
}
