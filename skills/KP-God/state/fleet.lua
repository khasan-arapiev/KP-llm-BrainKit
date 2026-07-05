local wezterm = require 'wezterm'
local config = wezterm.config_builder()
config.window_decorations = "RESIZE"
config.window_close_confirmation = "AlwaysPrompt"
config.show_close_tab_button_in_tabs = false
return config
