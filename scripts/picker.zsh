#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════
#  PICKER — Termdom Smart Project Launcher
#
#  Scans your project directories, detects tech stack, opens Neovim,
#  and sets the Niri window layout to match the project type.
#
#  Usage:
#    pick              → fuzzy-find and launch a project
#    pick /path/to/dir → open a specific directory
#    pick -a           → add current dir as a pinned project
#    pick -l           → list all projects
#
#  Stack detection:
#    C/C++/Rust/Assembly → 100% width  (full focus, systems work)
#    Web / React / TS    → 70% editor + 30% terminal
#    Python / Generic    → 80% width
# ══════════════════════════════════════════════════════════════════

# ─────────────────────────────────────────────────────────────────
#  USER CONFIGURATION
# ─────────────────────────────────────────────────────────────────
PROJECT_DIRS=(
    "$HOME/projects"
    "$HOME/dev"
    "$HOME/work"
    "$HOME/src"
)

# Pinned projects file (one path per line)
PINNED_FILE="$HOME/.config/termdom/pinned_projects"

# Max depth to scan for projects
SCAN_DEPTH=3

# ─────────────────────────────────────────────────────────────────
#  Colour helpers
# ─────────────────────────────────────────────────────────────────
_cyan()   { echo -e "\033[1;36m$*\033[0m"; }
_green()  { echo -e "\033[1;32m$*\033[0m"; }
_yellow() { echo -e "\033[1;33m$*\033[0m"; }
_purple() { echo -e "\033[1;35m$*\033[0m"; }
_dim()    { echo -e "\033[0;90m$*\033[0m"; }

# ─────────────────────────────────────────────────────────────────
#  Stack Detection — returns a canonical type string
# ─────────────────────────────────────────────────────────────────
detect_stack() {
    local dir="$1"

    # Systems / Low-level
    [[ -f "$dir/Cargo.toml"                    ]] && { echo "rust";    return; }
    [[ -f "$dir/CMakeLists.txt"                ]] && { echo "cmake";   return; }
    [[ -f "$dir/Makefile" || -f "$dir/makefile"]] && {
        # Differentiate: if .cpp/.c files present → c/cpp
        local cpp_files
        cpp_files=$(find "$dir" -maxdepth 2 \( -name "*.cpp" -o -name "*.cc" \) 2>/dev/null | head -1)
        local c_files
        c_files=$(find "$dir" -maxdepth 2 -name "*.c" 2>/dev/null | head -1)
        local asm_files
        asm_files=$(find "$dir" -maxdepth 2 \( -name "*.asm" -o -name "*.s" \) 2>/dev/null | head -1)
        [[ -n "$cpp_files" ]] && { echo "cpp";     return; }
        [[ -n "$asm_files" ]] && { echo "asm";     return; }
        [[ -n "$c_files"   ]] && { echo "c";       return; }
        echo "make"; return
    }
    [[ -n "$(find "$dir" -maxdepth 2 -name "*.cpp" -o -name "*.cc" 2>/dev/null | head -1)" ]] && { echo "cpp"; return; }
    [[ -n "$(find "$dir" -maxdepth 2 -name "*.c"   2>/dev/null | head -1)" ]] && { echo "c";   return; }
    [[ -n "$(find "$dir" -maxdepth 2 \( -name "*.asm" -o -name "*.s" \) 2>/dev/null | head -1)" ]] && { echo "asm"; return; }

    # Web / Frontend
    [[ -f "$dir/package.json"                  ]] && {
        local pkg
        pkg=$(cat "$dir/package.json" 2>/dev/null)
        [[ "$pkg" == *'"react"'*               ]] && { echo "react";   return; }
        [[ "$pkg" == *'"vue"'*                 ]] && { echo "vue";     return; }
        [[ "$pkg" == *'"svelte"'*              ]] && { echo "svelte";  return; }
        [[ "$pkg" == *'"next"'* || "$pkg" == *'"nextjs"'* ]] && { echo "next"; return; }
        echo "node"; return
    }
    [[ -f "$dir/index.html" || -f "$dir/src/index.html" ]] && { echo "html"; return; }

    # Other
    [[ -f "$dir/pyproject.toml" || -f "$dir/setup.py" || -f "$dir/requirements.txt" ]] && { echo "python"; return; }
    [[ -f "$dir/build.gradle" || -f "$dir/pom.xml"    ]] && { echo "java";   return; }
    [[ -f "$dir/composer.json"                         ]] && { echo "php";    return; }
    [[ -f "$dir/go.mod"                                ]] && { echo "go";     return; }

    echo "generic"
}

# ─────────────────────────────────────────────────────────────────
#  Stack → Niri layout + display label
# ─────────────────────────────────────────────────────────────────
stack_layout() {
    local stack="$1"
    case "$stack" in
        rust|cmake|cpp|c|asm|make)
            echo "systems"   ;;   # 100% width
        react|vue|svelte|next|html|node)
            echo "webdev"    ;;   # 70% editor / 30% term
        python|java|php|go)
            echo "general"   ;;   # 80% width
        *)
            echo "general"   ;;
    esac
}

stack_icon() {
    case "$1" in
        rust)   echo "🦀 Rust"          ;;
        cmake)  echo "⚙  CMake / C++"   ;;
        cpp)    echo "⚡ C++"            ;;
        c)      echo "🔩 C"             ;;
        asm)    echo "🖥  Assembly"      ;;
        make)   echo "🔧 Makefile"       ;;
        react)  echo "⚛  React"         ;;
        vue)    echo "💚 Vue"            ;;
        svelte) echo "🔥 Svelte"         ;;
        next)   echo "▲  Next.js"        ;;
        node)   echo "🟢 Node.js"        ;;
        html)   echo "🌐 HTML/CSS"       ;;
        python) echo "🐍 Python"         ;;
        java)   echo "☕ Java"           ;;
        php)    echo "🐘 PHP"            ;;
        go)     echo "🔵 Go"             ;;
        *)      echo "📁 Generic"        ;;
    esac
}

# ─────────────────────────────────────────────────────────────────
#  Apply Niri layout
# ─────────────────────────────────────────────────────────────────
apply_niri_layout() {
    local layout="$1"

    if ! command -v niri &>/dev/null; then
        _dim "  → niri IPC not available (skipping layout)"; return
    fi

    case "$layout" in
        systems)
            _dim "  → Niri: 100% width (systems focus mode)"
            niri msg action set-column-width "100%" 2>/dev/null
            ;;
        webdev)
            _dim "  → Niri: 70% editor | 30% terminal (web dev split)"
            niri msg action set-column-width "70%" 2>/dev/null
            ;;
        general)
            _dim "  → Niri: 80% width"
            niri msg action set-column-width "80%" 2>/dev/null
            ;;
    esac
}

# ─────────────────────────────────────────────────────────────────
#  Gather all project directories
# ─────────────────────────────────────────────────────────────────
gather_projects() {
    local results=()

    # Pinned projects (highest priority)
    if [[ -f "$PINNED_FILE" ]]; then
        while IFS= read -r p; do
            [[ -d "$p" ]] && results+=("$p")
        done < "$PINNED_FILE"
    fi

    # Scan project dirs
    for base in "${PROJECT_DIRS[@]}"; do
        [[ ! -d "$base" ]] && continue
        while IFS= read -r -d '' dir; do
            # Skip hidden dirs and node_modules/target/build
            [[ "$dir" == *"/node_modules"* ]] && continue
            [[ "$dir" == *"/target"*       ]] && continue
            [[ "$dir" == *"/.git"*         ]] && continue
            [[ "$dir" == *"/build"*        ]] && continue
            [[ "$dir" == *"/__pycache__"*  ]] && continue

            # Only include dirs that look like project roots
            if [[ -f "$dir/Cargo.toml"      || -f "$dir/package.json"  ||
                  -f "$dir/CMakeLists.txt"   || -f "$dir/Makefile"      ||
                  -f "$dir/makefile"         || -f "$dir/pyproject.toml" ||
                  -f "$dir/go.mod"           || -f "$dir/composer.json"  ||
                  -f "$dir/pom.xml"          || -d "$dir/.git"           ||
                  -n "$(find "$dir" -maxdepth 1 -name "*.c" -o -name "*.cpp" -o -name "*.rs" 2>/dev/null | head -1)" ]]; then
                results+=("$dir")
            fi
        done < <(find "$base" -mindepth 1 -maxdepth "$SCAN_DEPTH" -type d -print0 2>/dev/null)
    done

    # Also add HOME itself and current dir as candidates
    results+=("$HOME")
    [[ "$PWD" != "$HOME" ]] && results+=("$PWD")

    # Deduplicate and print
    printf '%s\n' "${results[@]}" | awk '!seen[$0]++'
}

# ─────────────────────────────────────────────────────────────────
#  Launch project in Neovim
# ─────────────────────────────────────────────────────────────────
launch_project() {
    local dir="$1"

    if [[ ! -d "$dir" ]]; then
        echo "Directory not found: $dir"; exit 1
    fi

    local stack
    stack=$(detect_stack "$dir")
    local layout
    layout=$(stack_layout "$stack")
    local icon
    icon=$(stack_icon "$stack")

    _cyan "\n  📂 Project : $(basename "$dir")"
    _cyan "  $icon"
    _cyan "  📐 Layout  : $layout\n"

    # Apply niri layout BEFORE opening nvim
    apply_niri_layout "$layout"

    # cd and launch
    cd "$dir" || exit 1

    # For web dev: after opening nvim, hint to open a terminal split
    if [[ "$layout" == "webdev" ]]; then
        _dim "  → Tip: open a 30% terminal beside nvim with Niri's vertical split\n"
    fi

    # Launch Neovim (open file tree if lazyvim)
    nvim .
}

# ══════════════════════════════════════════════════════════════════
#  MAIN
# ══════════════════════════════════════════════════════════════════
case "${1:-}" in
    # ── Direct path ─────────────────────────────────────────────
    /*)
        launch_project "$1"
        ;;

    # ── Pin current directory ────────────────────────────────────
    -a|--add)
        mkdir -p "$(dirname "$PINNED_FILE")"
        local target="${2:-$PWD}"
        if grep -qxF "$target" "$PINNED_FILE" 2>/dev/null; then
            _yellow "Already pinned: $target"
        else
            echo "$target" >> "$PINNED_FILE"
            _green "✓ Pinned: $target"
        fi
        ;;

    # ── List all projects ────────────────────────────────────────
    -l|--list)
        _cyan "━━━ Discovered Projects ━━━"
        gather_projects | while IFS= read -r dir; do
            local stack
            stack=$(detect_stack "$dir")
            printf "  %-50s  %s\n" "$(echo "$dir" | sed "s|$HOME|~|")" "$(stack_icon "$stack")"
        done
        ;;

    # ── Fuzzy pick (default) ─────────────────────────────────────
    "")
        if ! command -v fzf &>/dev/null; then
            _yellow "fzf not found. Install: sudo apt install fzf"
            exit 1
        fi

        # Build preview command for fzf
        local preview_cmd='
            dir={}
            echo "Path: {}"
            echo ""
            ls --color=always -lh "$dir" 2>/dev/null | head -20
        '

        local selected
        selected=$(
            gather_projects \
            | sed "s|$HOME|~|g" \
            | fzf \
                --prompt="  Project › " \
                --header="Pick a project — Enter to open, Ctrl-C to cancel" \
                --preview="dir=\$(echo {} | sed \"s|~|$HOME|\"); ls --color=always \"\$dir\" 2>/dev/null | head -20" \
                --preview-window="right:40%:wrap" \
                --height=70% \
                --border=rounded \
                --color="header:italic,border:cyan,prompt:cyan" \
                --ansi
        )

        if [[ -z "$selected" ]]; then
            _dim "No project selected."; exit 0
        fi

        # Expand ~ back to full path
        selected=$(echo "$selected" | sed "s|^~|$HOME|")
        launch_project "$selected"
        ;;

    *)
        echo "Usage: pick [/path] [-a [path]] [-l]"
        ;;
esac
