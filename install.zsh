#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════
#  TERMDOM — Master Install Script
#  Run once: zsh install.zsh
#
#  What this does:
#    1. Detects your distro and installs dependencies
#    2. Copies all Termdom configs to the right locations
#    3. Backs up any existing configs before overwriting
#    4. Adds the source line to ~/.zshrc
#    5. Sets executable bits on all scripts
#    6. Creates wallpaper directory structure
# ══════════════════════════════════════════════════════════════════

set -euo pipefail

TERMDOM_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="$HOME/.config/termdom/backups/$(date +%Y%m%d_%H%M%S)"
CONFIG_DIR="$HOME/.config/termdom"

# ── Colours ───────────────────────────────────────────────────────
_h()  { echo -e "\n\033[1;35m══ $* \033[0m"; }
_ok() { echo -e "  \033[1;32m✓\033[0m  $*"; }
_sk() { echo -e "  \033[0;90m↷\033[0m  $* (skipped — already exists)"; }
_wn() { echo -e "  \033[1;33m⚠\033[0m  $*"; }
_er() { echo -e "  \033[1;31m✗\033[0m  $*"; }

# ── Detect distro ─────────────────────────────────────────────────
detect_distro() {
    if command -v pacman &>/dev/null; then echo "arch"
    elif command -v apt &>/dev/null;  then echo "debian"
    elif command -v dnf &>/dev/null;  then echo "fedora"
    else echo "unknown"; fi
}

# ── Install packages ──────────────────────────────────────────────
install_deps() {
    _h "Installing Dependencies"
    local distro
    distro=$(detect_distro)

    echo "  Detected: $distro"

    case "$distro" in
        arch)
            local pkgs=(figlet lolcat fortune-mod cowsay fastfetch fzf swww nodejs npm)
            local aur_pkgs=(wezterm-git)
            echo "  Running: sudo pacman -S --needed ${pkgs[*]}"
            sudo pacman -S --needed --noconfirm "${pkgs[@]}" 2>/dev/null || \
                _wn "Some pacman packages failed — install manually"
            if command -v yay &>/dev/null; then
                yay -S --needed --noconfirm "${aur_pkgs[@]}" 2>/dev/null || true
            else
                _wn "yay not found — install WezTerm manually from AUR"
            fi
            ;;
        debian)
            sudo apt update -qq
            sudo apt install -y figlet lolcat fortune cowsay fastfetch fzf nodejs npm 2>/dev/null || \
                _wn "Some apt packages failed — install manually"
            _wn "swww: install from https://github.com/LGFae/swww/releases"
            _wn "WezTerm: install from https://wezfurlong.org/wezterm/install/linux.html"
            ;;
        *)
            _wn "Unknown distro — install these manually:"
            echo "     figlet lolcat fortune cowsay fastfetch fzf swww nodejs npm wezterm"
            ;;
    esac

    # Install lolcat via gem if not available
    if ! command -v lolcat &>/dev/null; then
        _wn "lolcat not found, trying gem install..."
        gem install lolcat 2>/dev/null && _ok "lolcat installed via gem" || \
            _wn "Install lolcat manually: gem install lolcat"
    fi

    _ok "Dependency step complete"
}

# ── Backup a file before overwriting ─────────────────────────────
backup_file() {
    local src="$1"
    if [[ -f "$src" || -d "$src" ]]; then
        mkdir -p "$BACKUP_DIR"
        local rel
        rel=$(echo "$src" | sed "s|$HOME/||")
        local dest="$BACKUP_DIR/$rel"
        mkdir -p "$(dirname "$dest")"
        cp -r "$src" "$dest"
        _ok "Backed up: $src → $BACKUP_DIR/$rel"
    fi
}

# ── Copy with backup ──────────────────────────────────────────────
deploy_file() {
    local src="$1"
    local dst="$2"
    mkdir -p "$(dirname "$dst")"
    backup_file "$dst"
    cp "$src" "$dst"
    _ok "Deployed: $dst"
}

# ─────────────────────────────────────────────────────────────────
#  INSTALL STEPS
# ─────────────────────────────────────────────────────────────────

_h "Setting Up Termdom Directory Structure"
mkdir -p "$CONFIG_DIR"/{scripts,backups}
mkdir -p "$HOME/wallpapers"
_ok "Directories created"

_h "Deploying Scripts"
deploy_file "$TERMDOM_DIR/scripts/clog.zsh"         "$CONFIG_DIR/scripts/clog.zsh"
deploy_file "$TERMDOM_DIR/scripts/theme-toggle.zsh" "$CONFIG_DIR/scripts/theme-toggle.zsh"
deploy_file "$TERMDOM_DIR/scripts/picker.zsh"       "$CONFIG_DIR/scripts/picker.zsh"
deploy_file "$TERMDOM_DIR/zsh/termdom.zsh"          "$CONFIG_DIR/zsh/termdom.zsh"

# Make scripts executable
chmod +x "$CONFIG_DIR/scripts/"*.zsh
chmod +x "$CONFIG_DIR/zsh/termdom.zsh"
_ok "Executable bits set"

_h "Deploying WezTerm Config"
mkdir -p "$HOME/.config/wezterm"
if [[ -f "$HOME/.config/wezterm/wezterm.lua" ]]; then
    _wn "WezTerm config already exists — backing up and merging"
    backup_file "$HOME/.config/wezterm/wezterm.lua"
fi
deploy_file "$TERMDOM_DIR/wezterm/wezterm.lua" "$HOME/.config/wezterm/wezterm.lua"

_h "Deploying Neovim Autocmds"
mkdir -p "$HOME/.config/nvim/lua/config"
local nvim_autocmds="$HOME/.config/nvim/lua/config/autocmds.lua"
if [[ -f "$nvim_autocmds" ]]; then
    _wn "autocmds.lua exists — appending Termdom block"
    backup_file "$nvim_autocmds"
    echo "" >> "$nvim_autocmds"
    echo "-- ── Termdom Auto-Compile (appended by installer) ────────────────" >> "$nvim_autocmds"
    cat "$TERMDOM_DIR/nvim/autocmds.lua" >> "$nvim_autocmds"
else
    deploy_file "$TERMDOM_DIR/nvim/autocmds.lua" "$nvim_autocmds"
fi

_h "Deploying Niri Config Additions"
local niri_cfg="$HOME/.config/niri/config.kdl"
if [[ -f "$niri_cfg" ]]; then
    _wn "Your niri config.kdl already exists."
    _wn "Manually merge the additions from:"
    _wn "  $TERMDOM_DIR/niri/config_additions.kdl"
    cp "$TERMDOM_DIR/niri/config_additions.kdl" "$CONFIG_DIR/niri_additions.kdl"
    _ok "Reference copy saved to: $CONFIG_DIR/niri_additions.kdl"
else
    mkdir -p "$HOME/.config/niri"
    cp "$TERMDOM_DIR/niri/config_additions.kdl" "$niri_cfg"
    _ok "Niri config deployed (new install)"
fi

_h "Writing Wallpaper Readme"
cat > "$HOME/wallpapers/README.md" <<'README'
# Termdom Wallpapers

Place your wallpapers here with these exact names for the theme switcher:

| File           | Used by            |
|----------------|--------------------|
| `mocha.jpg`    | Catppuccin Mocha (dark theme)  |
| `latte.jpg`    | Catppuccin Latte (light theme) |

Supported formats: `.jpg`, `.png`, `.webp`

If the specific files are missing, the theme switcher will pick a random image from this directory.

## Recommendations
- Catppuccin wallpapers: https://github.com/zhichaoh/catppuccin-wallpapers
README
_ok "Wallpaper directory ready at ~/wallpapers/"

_h "Setting Up Initial Theme State"
echo "mocha" > "$CONFIG_DIR/current_theme"
echo "mocha" > "$CONFIG_DIR/nvim_theme.lua"
_ok "Default theme: mocha (dark)"

_h "Patching ~/.zshrc"
local zshrc="$HOME/.zshrc"
local source_line="source \"\$HOME/.config/termdom/zsh/termdom.zsh\""

if grep -qF "termdom.zsh" "$zshrc" 2>/dev/null; then
    _sk "termdom.zsh already sourced in ~/.zshrc"
else
    backup_file "$zshrc"
    echo "" >> "$zshrc"
    echo "# ── Termdom Entrance Sequence ─────────────────────────────" >> "$zshrc"
    echo "$source_line" >> "$zshrc"
    _ok "Added source line to ~/.zshrc"
fi

_h "Creating Pinned Projects File"
local pinned="$CONFIG_DIR/pinned_projects"
if [[ ! -f "$pinned" ]]; then
    touch "$pinned"
    # Pre-pin common dirs if they exist
    for d in "$HOME/projects" "$HOME/dev" "$HOME/src"; do
        [[ -d "$d" ]] && echo "$d" >> "$pinned"
    done
    _ok "Pinned projects: $pinned"
fi

# ── Summary ───────────────────────────────────────────────────────
_h "Installation Complete 🎉"
echo ""
echo "  \033[1;36mQuick Reference:\033[0m"
echo "  ─────────────────────────────────────────────"
echo "  theme          → toggle Mocha ↔ Latte + wallpaper"
echo "  pick           → fuzzy project launcher"
echo "  clog \"msg\"    → log a system change"
echo "  lazysql        → open nvim DBUI"
echo "  <leader>b      → manual build in neovim"
echo "  <leader>r      → run binary / cargo run"
echo "  Super+P        → project picker (niri)"
echo "  Super+Shift+T  → theme toggle (niri)"
echo "  Super+F        → 100% width / systems mode"
echo "  Super+W        → 70% width / web dev mode"
echo "  F5 in WezTerm  → theme toggle"
echo "  ─────────────────────────────────────────────"
echo ""
echo "  \033[1;33mNext steps:\033[0m"
echo "  1. Add wallpapers: ~/wallpapers/mocha.jpg + latte.jpg"
echo "  2. Merge niri keybindings from: $CONFIG_DIR/niri_additions.kdl"
echo "  3. Reload zsh: exec zsh"
echo ""
