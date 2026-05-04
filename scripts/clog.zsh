#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════
#  CLOG — Termdom Changelog Logger
#  Usage:
#    clog "Added new keybinding for project picker"
#    clog                    # Interactive multi-line mode
#    clog -l                 # List last 10 entries
#    clog -s "keyword"       # Search changelog
#    clog -o                 # Open changelog in $EDITOR
#
#  Output: ~/Termdom_Changelog.md  (timestamped Markdown entries)
# ══════════════════════════════════════════════════════════════════

CHANGELOG="$HOME/Termdom_Changelog.md"

# ── Colour helpers ─────────────────────────────────────────────────
_cyan()  { echo -e "\033[1;36m$*\033[0m"; }
_green() { echo -e "\033[1;32m$*\033[0m"; }
_red()   { echo -e "\033[1;31m$*\033[0m"; }
_dim()   { echo -e "\033[0;90m$*\033[0m"; }

# ── Create changelog with header if missing ───────────────────────
_ensure_changelog() {
    if [[ ! -f "$CHANGELOG" ]]; then
        cat > "$CHANGELOG" <<'HEADER'
# 📜 Termdom Changelog
> **Lord Mathews' System Evolution Log**
> Every command, every tweak, every upgrade — recorded.
> Format: `clog "what you changed"` | Search: `clog -s keyword`

---

HEADER
        _green "✓ Created $CHANGELOG"
    fi
}

# ── Detect current git context ─────────────────────────────────────
_git_context() {
    if git rev-parse --git-dir &>/dev/null 2>&1; then
        local branch
        branch=$(git symbolic-ref --short HEAD 2>/dev/null || echo "detached")
        local dirty
        dirty=$(git status --short 2>/dev/null | head -3 | tr '\n' ' ' | sed 's/ $//')
        echo "**Branch:** \`$branch\` | **Modified:** \`${dirty:-clean}\`"
    fi
}

# ── Detect what config files changed recently ──────────────────────
_recent_changes() {
    # Files modified in the last 5 minutes in config dirs
    local changed
    changed=$(find ~/.config ~/.zshrc ~/.zprofile 2>/dev/null \
        -maxdepth 4 -newer "$CHANGELOG" -type f \
        ! -path "*/cache/*" ! -path "*/.git/*" \
        2>/dev/null | head -5 | sed 's|'"$HOME"'|~|g' | tr '\n' ', ' | sed 's/,$//')
    [[ -n "$changed" ]] && echo "**Auto-detected changes:** \`$changed\`"
}

# ── Write a log entry ──────────────────────────────────────────────
_write_entry() {
    local change="$1"
    local timestamp
    timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    local day
    day=$(date "+%A, %B %d %Y")
    local git_ctx
    git_ctx=$(_git_context)
    local auto_ctx
    auto_ctx=$(_recent_changes)

    {
        echo ""
        echo "### 🕐 \`$timestamp\` — $day"
        echo ""
        echo "**Change:** $change"
        [[ -n "$git_ctx"  ]] && echo "$git_ctx"
        [[ -n "$auto_ctx" ]] && echo "$auto_ctx"
        echo ""
        echo "---"
    } >> "$CHANGELOG"

    _green "✓ Logged [$timestamp]"
    _dim   "  → $CHANGELOG"
}

# ── Subcommand: list recent entries ───────────────────────────────
_clog_list() {
    local n="${1:-10}"
    if [[ ! -f "$CHANGELOG" ]]; then
        _red "No changelog found. Run: clog \"first entry\""; return 1
    fi
    _cyan "━━━ Last $n Entries ━━━"
    grep -n "^### 🕐" "$CHANGELOG" | tail -"$n" | while IFS= read -r line; do
        _dim "$line"
    done
}

# ── Subcommand: search entries ─────────────────────────────────────
_clog_search() {
    local term="$1"
    if [[ -z "$term" ]]; then _red "Usage: clog -s <keyword>"; return 1; fi
    if [[ ! -f "$CHANGELOG" ]]; then _red "No changelog found."; return 1; fi
    _cyan "━━━ Search: \"$term\" ━━━"
    grep -n -i "$term" "$CHANGELOG" | while IFS= read -r line; do
        echo "$line" | sed "s/$term/\033[1;33m$term\033[0m/Ig"
    done
}

# ══════════════════════════════════════════════════════════════════
#  MAIN ENTRY POINT
# ══════════════════════════════════════════════════════════════════
case "$1" in
    -l|--list)
        _clog_list "$2"
        ;;
    -s|--search)
        _clog_search "$2"
        ;;
    -o|--open)
        ${EDITOR:-nvim} "$CHANGELOG"
        ;;
    -h|--help)
        _cyan "clog — Termdom Changelog Logger"
        echo ""
        echo "  clog \"message\"   Log a change"
        echo "  clog             Interactive mode"
        echo "  clog -l [n]      List last n entries (default 10)"
        echo "  clog -s keyword  Search the changelog"
        echo "  clog -o          Open changelog in \$EDITOR"
        ;;
    "")
        # Interactive multi-line mode
        _ensure_changelog
        _cyan "[Termdom Clog] — Describe the change (blank line to finish):"
        local lines=()
        while IFS= read -r line; do
            [[ -z "$line" ]] && break
            lines+=("$line")
        done
        if [[ ${#lines[@]} -eq 0 ]]; then
            _dim "Nothing logged."; exit 0
        fi
        _write_entry "$(printf '%s\n' "${lines[@]}")"
        ;;
    *)
        # Inline message: clog "message here"
        _ensure_changelog
        _write_entry "$*"
        ;;
esac
