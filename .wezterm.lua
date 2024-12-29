local wezterm = require("wezterm")

local config = wezterm.config_builder()

config.color_scheme = "Apple System Colors"
config.font = wezterm.font("JetBrainsMono Nerd Font")
config.window_background_opacity = 0.8
config.macos_window_background_blur = 10
config.enable_tab_bar = false
config.window_decorations = "RESIZE | INTEGRATED_BUTTONS"
config.font_size = 16

config.window_padding = {
	left = 0,
	right = 16,
	top = 64,
	bottom = 0,
}

return config
