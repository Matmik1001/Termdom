#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════
#  THEME-TOGGLE — Termdom Catppuccin Switcher
#
#  Toggles Neovim + WezTerm between Catppuccin Mocha (dark) and
#  Catppuccin Latte (light). Also swaps your wallpaper via swww
#  with a smooth fade transition.
#
#  Usage:
#    theme           → auto-toggle (flips current theme)
#    theme mocha     → force dark
#    theme latte     → force light
#    theme status    → print current theme
#
#  ── Configure your wallpaper paths below ──────────────────────
# ══════════════════════════════════════════════════════════════════

# ─────────────────────────────────────────────────────────────────
#  USER CONFIGURATION — edit these paths
# ─────────────────────────────────────────────────────────────────
WALLPAPER_MOCHA="$HOME/wallpapers/mocha.jpg"        # dark wallpaper
WALLPAPER_LATTE="$HOME/wallpapers/latte.jpg"        # light wallpaper
WALLPAPER_DIR="$HOME/wallpapers"                     # fallback: pick random from dir

THEME_STATE="$HOME/.config/termdom/current_theme"   # state file
NVIM_THEME_LUA="$HOME/.config/termdom/nvim_theme.lua" # read by nvim colorscheme plugin
WEZTERM_CONFIG="$HOME/.config/wezterm/wezterm.lua"

SWWW_TRANSITION="fade"          # fade | wipe | wave | grow | outer
SWWW_DURATION=1                 # seconds for transition
SWWW_FPS=60

# ─────────────────────────────────────────────────────────────────
#  Colour helpers
# ─────────────────────────────────────────────────────────────────
_cyan()   { echo -e "\033[1;36m$*\033[0m"; }
_purple() { echo -e "\033[1;35m$*\033[0m"; }
_yellow() { echo -e "\033[1;33m$*\033[0m"; }
_green()  { echo -e "\033[1;32m$*\033[0m"; }
_dim()    { echo -e "\033[0;90m$*\033[0m"; }

# ─────────────────────────────────────────────────────────────────
#  Read / Write theme state
# ─────────────────────────────────────────────────────────────────
_read_theme() {
    mkdir -p "$(dirname "$THEME_STATE")"
    [[ -f "$THEME_STATE" ]] && cat "$THEME_STATE" || echo "mocha"
}

_write_theme() {
    mkdir -p "$(dirname "$THEME_STATE")"
    echo "$1" > "$THEME_STATE"
}

# ─────────────────────────────────────────────────────────────────
#  Neovim: write a small Lua file that your colorscheme plugin reads
#  In your ~/.config/nvim/lua/plugins/colorscheme.lua, add:
#
#    local function termdom_flavor()
#      local f = io.open(vim.fn.expand("~/.config/termdom/nvim_theme.lua"), "r")
#      if f then local t = f:read("*l"); f:close(); return t or "mocha" end
#      return "mocha"
#    end
#    return { "catppuccin/nvim", name = "catppuccin", priority = 1000,
#      opts = { flavour = termdom_flavor() } }
# ─────────────────────────────────────────────────────────────────
_apply_nvim_theme() {
    local flavor="$1"
    echo "$flavor" > "$NVIM_THEME_LUA"

    # If Neovim is running, hot-swap via server sockets
    local sockets
    sockets=$(ls /tmp/nvim*/0 2>/dev/null || ls /tmp/nvim.*/nvim.* 2>/dev/null | head -5)
    if [[ -n "$sockets" ]]; then
        for sock in $(echo "$sockets"); do
            nvim --server "$sock" --remote-send \
                "<cmd>lua vim.cmd('colorscheme catppuccin-$flavor')<CR>" 2>/dev/null &
        done
        _dim "  → Hot-swapped Neovim theme"
    else
        _dim "  → Neovim theme set (takes effect on next launch)"
    fi
}

# ─────────────────────────────────────────────────────────────────
#  WezTerm: append/replace the color_scheme line in wezterm.lua
#  This works because WezTerm hot-reloads its config automatically
#  (ensure: config.automatically_reload_config = true in wezterm.lua)
# ─────────────────────────────────────────────────────────────────
_apply_wezterm_theme() {
    local flavor="$1"
    local scheme

    if [[ "$flavor" == "latte" ]]; then
        scheme="Catppuccin Latte"
    else
        scheme="Catppuccin Mocha"
    fi

    if [[ ! -f "$WEZTERM_CONFIG" ]]; then
        _dim "  → WezTerm config not found at $WEZTERM_CONFIG (skip)"
        return
    fi

    # Replace the color_scheme line if it exists; otherwise append
    if grep -q "color_scheme" "$WEZTERM_CONFIG"; then
        sed -i "s|color_scheme = \"Catppuccin.*\"|color_scheme = \"$scheme\"|g" "$WEZTERM_CONFIG"
    else
        # Insert before the last 'return config' line
        sed -i "/^return config/i config.color_scheme = \"$scheme\"" "$WEZTERM_CONFIG"
    fi

    _dim "  → WezTerm theme updated (auto-reloads)"
}

# ─────────────────────────────────────────────────────────────────
#  Wallpaper swap via swww
# ─────────────────────────────────────────────────────────────────
_apply_wallpaper() {
    local flavor="$1"

    if ! command -v swww &>/dev/null; then
        _dim "  → swww not found, skipping wallpaper (install: yay -S swww)"
        return
    fi

    # Ensure swww daemon is running
    swww query &>/dev/null || swww init

    local wallpaper
    if [[ "$flavor" == "latte" ]]; then
        wallpaper="$WALLPAPER_LATTE"
    else
        wallpaper="$WALLPAPER_MOCHA"
    fi

    # Fallback: pick a random image from wallpaper dir
    if [[ ! -f "$wallpaper" ]]; then
        _dim "  → Configured wallpaper not found, picking random from $WALLPAPER_DIR"
        wallpaper=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.webp" \) \
            2>/dev/null | shuf | head -1)
    fi

    if [[ -z "$wallpaper" ]]; then
        _dim "  → No wallpaper found in $WALLPAPER_DIR (skip)"
        return
    fi

    swww img "$wallpaper" \
        --transition-type  "$SWWW_TRANSITION" \
        --transition-duration "$SWWW_DURATION" \
        --transition-fps   "$SWWW_FPS" \
        && _dim "  → Wallpaper: $(basename "$wallpaper")"
}

# ─────────────────────────────────────────────────────────────────
#  Main apply function
# ─────────────────────────────────────────────────────────────────
_apply_theme() {
    local flavor="$1"

    if [[ "$flavor" != "mocha" && "$flavor" != "latte" ]]; then
        echo "Unknown theme '$flavor'. Use: mocha | latte"; exit 1
    fi

    if [[ "$flavor" == "mocha" ]]; then
        _purple "🌙  Switching to Catppuccin Mocha (dark)"
    else
        _yellow "☀   Switching to Catppuccin Latte (light)"
    fi

    _apply_nvim_theme    "$flavor"
    _apply_wezterm_theme "$flavor"
    _apply_wallpaper     "$flavor"
    _write_theme         "$flavor"

    _green "\n✓ Theme switched to: $flavor"
}

# ══════════════════════════════════════════════════════════════════
#  MAIN
# ══════════════════════════════════════════════════════════════════
case "${1:-toggle}" in
    toggle|"")
        current=$(_read_theme)
        if [[ "$current" == "mocha" ]]; then
            _apply_theme "latte"
        else
            _apply_theme "mocha"
        fi
        ;;
    mocha|dark)   _apply_theme "mocha" ;;
    latte|light)  _apply_theme "latte" ;;
    status)
        current=$(_read_theme)
        [[ "$current" == "mocha" ]] && _purple "🌙  Current theme: mocha (dark)" \
                                    || _yellow "☀   Current theme: latte (light)"
        ;;
    *)
        echo "Usage: theme [toggle|mocha|latte|status]"
        ;;
esac
