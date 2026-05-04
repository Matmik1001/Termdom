#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════
#  LORD MATHEWS TERMDOM — Zsh Entrance Sequence
#
#  IMPORTANT: Source this at the VERY BOTTOM of ~/.zshrc,
#  AFTER the p10k source lines. This prevents Powerlevel10k
#  instant-prompt conflicts and ensures lolcat gets full color.
#
#  Add to bottom of ~/.zshrc:
#    source "$HOME/.config/termdom/zsh/termdom.zsh"
# ══════════════════════════════════════════════════════════════════

# ── Guard: only run in interactive shells ─────────────────────────
[[ $- != *i* ]] && return

# ── Guard: only run once per session ──────────────────────────────
[[ -n "$TERMDOM_LOADED" ]] && return
export TERMDOM_LOADED=1

# ══════════════════════════════════════════════════════════════════
#  SECTION 1 — Animated 3D Header
# ══════════════════════════════════════════════════════════════════
_termdom_header() {
    if ! command -v figlet &>/dev/null || ! command -v lolcat &>/dev/null; then
        echo -e "\033[1;35m  LORD MATHEWS TERMDOM\033[0m"
        return
    fi

    # Search for 3d.flf in all known font directories
    local font_dirs=(
        "$HOME/.local/share/figlet-fonts"
        "/usr/share/figlet"
        "/usr/share/figlet/fonts"
        "/usr/share/fonts/figlet"
        "/usr/local/share/figlet"
    )

    local font_path=""
    for d in "${font_dirs[@]}"; do
        if [[ -f "$d/3d.flf" ]]; then
            font_path="$d/3d.flf"
            break
        fi
    done

    local cols
    cols=$(tput cols 2>/dev/null || echo 120)

    # -f forces lolcat to output colour even inside a pipe
    if [[ -n "$font_path" ]]; then
        figlet -f "$font_path" -w "$cols" "Lord Mathews" | lolcat -f -a -d 3 -s 180
        figlet -f "$font_path" -w "$cols" "  Termdom"    | lolcat -f -a -d 3 -s 180
    else
        # Fallback font chain
        local fallback_font=""
        for candidate in larry3d big banner3 slant standard; do
            for d in "${font_dirs[@]}"; do
                if [[ -f "$d/${candidate}.flf" ]]; then
                    fallback_font="$d/${candidate}.flf"
                    break 2
                fi
            done
        done

        if [[ -n "$fallback_font" ]]; then
            figlet -f "$fallback_font" -w "$cols" "Lord Mathews Termdom" | lolcat -f -a -d 3 -s 180
        else
            echo "Lord Mathews Termdom" | lolcat -f -a -d 3
        fi
    fi
    echo ""
}

# ══════════════════════════════════════════════════════════════════
#  SECTION 2 — Fortune Wisdom via Cowsay
# ══════════════════════════════════════════════════════════════════
_termdom_wisdom() {
    if command -v fortune &>/dev/null && command -v cowsay &>/dev/null; then
        local cows=(tux default dragon-and-cow elephant ghostbusters koala)
        local cow=${cows[$RANDOM % ${#cows[@]}]}
        echo ""
        if command -v lolcat &>/dev/null; then
            fortune | cowsay -f "$cow" | lolcat -f
        else
            fortune | cowsay -f "$cow"
        fi
        echo ""
    fi
}

# ══════════════════════════════════════════════════════════════════
#  SECTION 3 — Fastfetch System Snapshot
# ══════════════════════════════════════════════════════════════════
_termdom_fetch() {
    local custom_cfg="$HOME/.config/fastfetch/config.jsonc"
    if command -v fastfetch &>/dev/null; then
        if [[ -f "$custom_cfg" ]]; then
            fastfetch --config "$custom_cfg"
        else
            fastfetch
        fi
    elif command -v neofetch &>/dev/null; then
        neofetch
    fi
}

# ══════════════════════════════════════════════════════════════════
#  SECTION 4 — Master Greeting (Typewriter Effect)
# ══════════════════════════════════════════════════════════════════
_termdom_greet() {
    local msg="  Welcome master Mathews, here I am to do the work that you want me to. For you I devote."
    local delay=0.025
    echo ""
    echo -ne "\033[1;36m"
    for (( i = 0; i < ${#msg}; i++ )); do
        echo -ne "${msg:$i:1}"
        sleep $delay
    done
    echo -e "\033[0m"
    echo ""
}

# ══════════════════════════════════════════════════════════════════
#  SECTION 5 — Current Theme Badge
# ══════════════════════════════════════════════════════════════════
_termdom_theme_badge() {
    local theme_file="$HOME/.config/termdom/current_theme"
    local theme="mocha"
    [[ -f "$theme_file" ]] && theme=$(<"$theme_file")
    if [[ "$theme" == "latte" ]]; then
        echo -e "  \033[0;33m☀  Theme: Catppuccin Latte\033[0m\n"
    else
        echo -e "  \033[0;35m🌙  Theme: Catppuccin Mocha\033[0m\n"
    fi
}

# ══════════════════════════════════════════════════════════════════
#  SECTION 6 — Run Sequence
# ══════════════════════════════════════════════════════════════════
_termdom_header
_termdom_wisdom
_termdom_fetch
_termdom_greet
_termdom_theme_badge

# ══════════════════════════════════════════════════════════════════
#  SECTION 7 — Aliases
# ══════════════════════════════════════════════════════════════════
alias lazysql="nvim -c 'DBUI'"
alias clog="$HOME/.config/termdom/scripts/clog.zsh"
alias pick="$HOME/.config/termdom/scripts/picker.zsh"
alias theme="$HOME/.config/termdom/scripts/theme-toggle.zsh"

alias dev="cd ~/projects && pick"
alias nv="nvim"
alias nvc="nvim ~/.config/nvim/"
alias niri-conf="nvim ~/.config/niri/config.kdl"
alias wez-conf="nvim ~/.config/wezterm/wezterm.lua"
alias zshrc="nvim ~/.zshrc"

alias cxx="g++ -std=c++20 -Wall -Wextra -g -o"
alias ccc="gcc -Wall -Wextra -g -o"
alias rb="cargo build"
alias rr="cargo run"
alias rt="cargo test"

alias lay-full="niri msg action set-column-width '100%'"
alias lay-web="niri msg action set-column-width '70%'"
alias lay-half="niri msg action set-column-width '50%'"
