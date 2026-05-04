-- ══════════════════════════════════════════════════════════════════
--  TERMDOM — WezTerm Configuration
--  File: ~/.config/wezterm/wezterm.lua
--
--  Features:
--    • Catppuccin Mocha/Latte theme (hot-reloads via theme-toggle.zsh)
--    • Startup: opens zsh which triggers the Termdom entrance sequence
--    • Fonts, opacity, padding, tab bar, keybindings
-- ══════════════════════════════════════════════════════════════════

local wezterm = require("wezterm")
local config  = wezterm.config_builder()
local act     = wezterm.action

-- ── Hot-reload (required for theme-toggle.zsh to work) ────────────
config.automatically_reload_config = true

-- ══════════════════════════════════════════════════════════════════
--  THEME — edit via: theme mocha | theme latte
-- ══════════════════════════════════════════════════════════════════
config.color_scheme = "Catppuccin Mocha"

-- ══════════════════════════════════════════════════════════════════
--  FONT
-- ══════════════════════════════════════════════════════════════════
config.font = wezterm.font_with_fallback({
  { family = "JetBrainsMono Nerd Font", weight = "Regular" },
  { family = "FiraCode Nerd Font",      weight = "Regular" },
  { family = "monospace" },
})
config.font_size             = 13.0
config.line_height           = 1.15
config.cell_width            = 1.0
config.freetype_load_target  = "Light"
config.freetype_render_target = "HorizontalLcd"

-- ══════════════════════════════════════════════════════════════════
--  WINDOW APPEARANCE
-- ══════════════════════════════════════════════════════════════════
config.window_background_opacity  = 0.93
config.text_background_opacity     = 1.0
config.window_decorations          = "RESIZE"
config.window_padding = {
  left   = 14,
  right  = 14,
  top    = 10,
  bottom = 8,
}
config.initial_rows = 38
config.initial_cols = 160

-- ══════════════════════════════════════════════════════════════════
--  TAB BAR
-- ══════════════════════════════════════════════════════════════════
config.enable_tab_bar          = true
config.use_fancy_tab_bar       = false
config.tab_bar_at_bottom       = true
config.hide_tab_bar_if_only_one_tab = false
config.tab_max_width           = 28

config.colors = {
  tab_bar = {
    background = "#1e1e2e",
    active_tab = {
      bg_color  = "#cba6f7",
      fg_color  = "#1e1e2e",
      intensity = "Bold",
    },
    inactive_tab = {
      bg_color = "#313244",
      fg_color = "#cdd6f4",
    },
    inactive_tab_hover = {
      bg_color = "#45475a",
      fg_color = "#cdd6f4",
    },
    new_tab = {
      bg_color = "#1e1e2e",
      fg_color = "#6c7086",
    },
    new_tab_hover = {
      bg_color = "#313244",
      fg_color = "#cdd6f4",
    },
  },
}

-- Tab title: show cwd short name
wezterm.on("format-tab-title", function(tab)
  local pane  = tab.active_pane
  local title = pane.title
  local cwd   = pane.current_working_dir
  if cwd then
    local dir = cwd.file_path:match("([^/]+)$") or cwd.file_path
    title = "  " .. dir .. "  "
  end
  return { { Text = title } }
end)

-- ══════════════════════════════════════════════════════════════════
--  SCROLLBACK & PERFORMANCE
-- ══════════════════════════════════════════════════════════════════
config.scrollback_lines       = 10000
config.enable_scroll_bar      = false
config.animation_fps          = 60
config.max_fps                = 120

-- ══════════════════════════════════════════════════════════════════
--  KEYBINDINGS
-- ══════════════════════════════════════════════════════════════════
config.keys = {
  -- New tab
  { key = "t",          mods = "CTRL|SHIFT", action = act.SpawnTab("CurrentPaneDomain") },
  -- Close tab
  { key = "w",          mods = "CTRL|SHIFT", action = act.CloseCurrentTab({ confirm = false }) },
  -- Vertical pane split
  { key = "d",          mods = "CTRL|SHIFT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
  -- Horizontal pane split
  { key = "e",          mods = "CTRL|SHIFT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
  -- Move between panes
  { key = "h",          mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Left")  },
  { key = "l",          mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Right") },
  { key = "k",          mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Up")    },
  { key = "j",          mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Down")  },
  -- Tab navigation
  { key = "LeftArrow",  mods = "CTRL|SHIFT", action = act.ActivateTabRelative(-1) },
  { key = "RightArrow", mods = "CTRL|SHIFT", action = act.ActivateTabRelative(1)  },
  -- Font size
  { key = "=",          mods = "CTRL",       action = act.IncreaseFontSize },
  { key = "-",          mods = "CTRL",       action = act.DecreaseFontSize },
  { key = "0",          mods = "CTRL",       action = act.ResetFontSize    },
  -- Theme toggle (calls your script)
  {
    key = "F5", mods = "",
    action = act.SpawnCommandInNewTab({
      args = { "zsh", "-c", "~/.config/termdom/scripts/theme-toggle.zsh && read -sk1" },
    }),
  },
  -- Project picker
  {
    key = "F2", mods = "",
    action = act.SpawnCommandInNewTab({
      args = { "zsh", "-c", "~/.config/termdom/scripts/picker.zsh" },
    }),
  },
  -- Full screen
  { key = "F11", mods = "", action = act.ToggleFullScreen },
  -- Copy / paste
  { key = "c",   mods = "CTRL|SHIFT", action = act.CopyTo("Clipboard")           },
  { key = "v",   mods = "CTRL|SHIFT", action = act.PasteFrom("Clipboard")        },
  -- Clear scrollback
  { key = "k",   mods = "CTRL",       action = act.ClearScrollback("ScrollbackOnly") },
}

-- ══════════════════════════════════════════════════════════════════
--  SHELL
-- ══════════════════════════════════════════════════════════════════
config.default_prog = { "/bin/zsh", "-l" }

-- ══════════════════════════════════════════════════════════════════
--  CURSOR
-- ══════════════════════════════════════════════════════════════════
config.default_cursor_style           = "BlinkingBar"
config.cursor_blink_rate              = 500
config.cursor_blink_ease_in           = "Constant"
config.cursor_blink_ease_out          = "Constant"

return config
