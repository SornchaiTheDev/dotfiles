return {
	"nvim-neo-tree/neo-tree.nvim",
	version = "*",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
		"MunifTanjim/nui.nvim",
	},
	cmd = "Neotree",
	keys = {
		{ "<leader>e", ":Neotree toggle position=current<CR>", { desc = "NeoTree toggle" } },
	},
	opts = {
		filesystem = {
			filtered_items = {
				visible = true,
				hide_dotfiles = false,
				hide_gitignored = true,
				never_show = {
					".git",
					".vscode",
					".idea",
				},
			},
			window = {
				mappings = {
					["\\"] = "close_window",
				},
			},
		},
	},
}
