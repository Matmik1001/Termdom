# TMUX Elite Configuration — Complete Reference
### v4.0 · Arch Linux · Lord Mathews Termdom · Neovim + C++ Systems Workflow

---

```
  Author  :  Matthews Mikondo  (Matias)
  OS      :  Arch Linux  (migrated from Ubuntu 24 LTS)
  WM      :  Niri  +  Hyprland   │   Theme: Catppuccin Mocha · Mauve/Lavender
  Term    :  WezTerm              │   Shell: Zsh + Powerlevel10k
  Editor  :  LazyVim (Neovim)    │   Brand: "Lord Mathews Termdom"
  Org     :  Ax-intl · Copperbelt University · Zambia
```

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Installation](#2-installation)
3. [Architecture Overview](#3-architecture-overview)
4. [Key Bindings Reference](#4-key-bindings-reference)
5. [Status Bar Legend](#5-status-bar-legend)
6. [Popup Commands](#6-popup-commands)
7. [Plugin Reference](#7-plugin-reference)
8. [Neovim Integration](#8-neovim-integration)
9. [Clipboard Integration](#9-clipboard-integration)
10. [Nested tmux / SSH Passthrough](#10-nested-tmux--ssh-passthrough)
11. [Session Persistence Guide](#11-session-persistence-guide)
12. [C++ Workflow Patterns](#12-c-workflow-patterns)
13. [Troubleshooting](#13-troubleshooting)

---

## 1. Prerequisites

Install all hard dependencies before applying the config.

```bash
# ── Arch Linux (pacman) ───────────────────────────────────────────────────────

# tmux >= 3.3  (Arch repos ship latest)
sudo pacman -S tmux

# fzf — required for popup session/window pickers
sudo pacman -S fzf

# Clipboard backends
sudo pacman -S wl-clipboard       # Wayland (Niri / Hyprland — primary)
sudo pacman -S xclip              # X11 fallback (if ever needed)

# Nerd Fonts — required for status bar glyphs (󰣐 󰊓 󰊤 etc.)
# Already in Arch repos via nerd-fonts group:
sudo pacman -S ttf-jetbrains-mono-nerd    # recommended for C++ / editor work
# Or install the full group (large download):
# sudo pacman -S nerd-fonts
# Then set WezTerm to use "JetBrainsMono Nerd Font" in wezterm.lua

# AUR helper shortcut (if using yay/paru):
# yay -S ttf-nerd-fonts-symbols-mono
```

Verify tmux version:
```bash
tmux -V     # must be >= 3.3
```

---

## 2. Installation

```bash
# 1. Create config directory
mkdir -p ~/.config/tmux

# 2. Place config file
cp tmux.conf ~/.config/tmux/tmux.conf

# 3. Install TPM (tmux plugin manager)
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# 4. Start tmux and install plugins
tmux
# Inside tmux: press  C-a I  (capital I) to install all plugins
# Wait for the "Done!" message at the bottom

# 5. Reload config
# C-a r
```

---

## 3. Architecture Overview

```
~/.config/tmux/
├── tmux.conf       ← main configuration (this file)
└── TMUX_DOCS.md    ← this documentation

~/.tmux/
└── plugins/
    ├── tpm/                    ← plugin manager
    ├── tmux-sensible/          ← sane baseline overrides
    ├── vim-tmux-navigator/     ← seamless Neovim ↔ tmux nav
    ├── tmux-resurrect/         ← session persistence
    ├── tmux-continuum/         ← auto-save resurrect state
    ├── tmux-yank/              ← clipboard bridge
    └── tmux-open/              ← URL/file opener from copy-mode
```

**Config section map:**

| Section | What it controls |
|---------|-----------------|
| § 1 PREFIX | Leader key (C-a) |
| § 2 TERMINAL | True color, undercurl, focus events |
| § 3 CORE | Escape time, history, mouse, indexing, activity |
| § 4 PANE APPEARANCE | Border style, display timers |
| § 5 STATUS BAR | Left/right panels, window tabs |
| § 6 SESSION & WINDOW | Splits, new session, kill commands |
| § 7 NAVIGATION | Window cycling, swap, last-window |
| § 8 PANE OPS | Resize, zoom, sync, mouse toggle |
| § 9 POPUP UTILITIES | Scratch terminal, fzf pickers, dev layout |
| § 10 HOUSEKEEPING | Reload, edit config, clear history |
| § 11 COPY MODE | Vi bindings, word boundaries, yank ops |
| § 12 NESTED TMUX | F12 SSH passthrough toggle |
| § 13 PLUGIN SETTINGS | Per-plugin configuration |
| § 14 PLUGINS | Plugin declarations |
| § 15 BOOTSTRAP | TPM runtime |

---

## 4. Key Bindings Reference

**Prefix:** `C-a` (Ctrl + a)

All bindings below that show `<prefix>` require pressing `C-a` first.

### Sessions

| Binding | Action |
|---------|--------|
| `<prefix> N` | New session with name prompt |
| `<prefix> C-s` | FZF session switcher popup |
| `<prefix> $` | Rename current session (tmux default, kept) |
| `<prefix> d` | Detach from session (tmux default, kept) |
| `<prefix> Q` | Kill server (all sessions) — asks for confirmation |

### Windows

| Binding | Action |
|---------|--------|
| `<prefix> c` | New window at current path |
| `<prefix> Tab` | Toggle last active window |
| `<prefix> C-h` | Previous window (repeatable) |
| `<prefix> C-l` | Next window (repeatable) |
| `<prefix> <` | Swap window left (repeatable) |
| `<prefix> >` | Swap window right (repeatable) |
| `<prefix> C-w` | FZF window finder popup (all sessions) |
| `<prefix> X` | Kill current window (no confirmation) |
| `<prefix> ,` | Rename current window (tmux default, kept) |
| `<prefix> 1–9` | Jump to window N (tmux default, kept) |

### Panes

| Binding | Action |
|---------|--------|
| `<prefix> \|` | Split vertically (new pane right, keeps cwd) |
| `<prefix> -` | Split horizontally (new pane below, keeps cwd) |
| `<prefix> f` | Toggle zoom / fullscreen |
| `<prefix> x` | Kill pane (no confirmation) |
| `<prefix> H/J/K/L` | Resize pane ← ↓ ↑ → by 5 (repeatable) |
| `<prefix> S` | Toggle pane sync (broadcast input to all panes) |
| `<prefix> m` | Toggle mouse on/off |
| `<prefix> q` | Show pane numbers briefly (tmux default, kept) |
| `<prefix> z` | Zoom pane (tmux default alias; `f` is the override) |

Pane navigation (no prefix needed — via vim-tmux-navigator):

| Binding | Action |
|---------|--------|
| `C-h` | Move to pane left (or Neovim split left) |
| `C-j` | Move to pane below (or Neovim split below) |
| `C-k` | Move to pane above (or Neovim split above) |
| `C-l` | Move to pane right (or Neovim split right) |
| `C-\` | Move to previous pane (or Neovim split) |

> Note: `C-l` for pane navigation conflicts with `<prefix> C-l` (clear history).
> They are distinct: bare `C-l` is handled by vim-tmux-navigator at the root table.

### Popup Utilities

| Binding | Action |
|---------|--------|
| `<prefix> ~` | Open scratch terminal popup (persistent session) |
| `<prefix> C-s` | FZF session switcher |
| `<prefix> C-w` | FZF window finder (all sessions) |
| `<prefix> D` | Apply dev layout (editor + terminal + build) |

### Housekeeping

| Binding | Action |
|---------|--------|
| `<prefix> r` | Reload tmux.conf |
| `<prefix> e` | Open tmux.conf in Neovim |
| `<prefix> C-l` | Clear screen + full scrollback history |
| `<prefix> u` | Enter copy-mode at top of history |
| `<prefix> /` | Enter copy-mode with backward search active |

### Copy Mode (`<prefix> [` to enter)

| Binding | Action |
|---------|--------|
| `v` | Begin character selection |
| `V` | Select whole line |
| `C-v` | Toggle block/column selection |
| `y` | Yank selection to clipboard + exit |
| `Y` | Yank entire line to clipboard |
| `D` | Yank from cursor to end of line |
| `q / Esc` | Exit copy-mode |
| `/` | Search backward |
| `?` | Search forward |
| `n / N` | Next / previous search result |
| `o` | Open selected URL/file (tmux-open) |
| `C-o` | Open selected file in Neovim (tmux-open) |

### Nested tmux / SSH

| Binding | Action |
|---------|--------|
| `F12` | Toggle SSH passthrough (dim status = inner mode active) |

---

## 5. Status Bar Legend

```
 󰣐 main  │  3w 2p  │  [dim]  │  󰊤 feat/parser  │  0.45 │  3.1G │  Wed 15 Apr │  14:23
 ───────────────────────────────────────────────────────────────────────────────────────
 ①          ②            ③              ④             ⑤       ⑥         ⑦           ⑧
```

| # | Color | Content |
|---|-------|---------|
| ① | Cyan | Session name (turns inverse cyan `PREFIX` when prefix is held) |
| ② | Dim grey | Window count (`w`) and pane count (`p`) in current window |
| ③ | Dim grey | Truncated pane title (current command / path) |
| ④ | Purple | Git branch of current pane's working directory; hidden if not in a repo |
| ⑤ | Yellow | 1-minute load average from `/proc/loadavg` (no subprocess delay) |
| ⑥ | Green | RAM currently in use (`free -h`) |
| ⑦ | Blue | Abbreviated weekday, day, and month |
| ⑧ | Cyan bold | Current time HH:MM |

**Window tab indicators:**

| Symbol | Meaning |
|--------|---------|
| `󰊓` | Pane in this window is zoomed |
| Yellow tab text | Window has unseen activity |
| Cyan bold tab | Currently active window |

---

## 6. Popup Commands

### Scratch Terminal (`<prefix> ~`)

Opens a floating terminal over your current session. The underlying tmux session
is named `scratch` and persists — closing the popup does not destroy it.
Re-open it any time with `<prefix> ~`. Use it for:
- Quick file lookups
- One-off `man` pages
- Git commits without leaving your editor window

### FZF Session Switcher (`<prefix> C-s`)

Lists all tmux sessions with window count and attached status. Fuzzy-search by
name. Selecting a session switches your client to it instantly.

### FZF Window Finder (`<prefix> C-w`)

Lists every window across every session. Shows session name, window index, window
name, and dimensions. Useful for jumping to a specific build window in a different
session without detaching.

### Dev Layout (`<prefix> D`)

Applies a three-pane layout optimized for C++ development:

```
┌─────────────────────────┬───────────────┐
│                         │               │
│    Pane 1 — Editor      │  Pane 2       │
│    (65% width)          │  Terminal     │
│                         │               │
│                         ├───────────────┤
│                         │               │
│                         │  Pane 3       │
│                         │  Build output │
└─────────────────────────┴───────────────┘
```

Focus returns to Pane 1 automatically. Run `nvim` in Pane 1, keep a shell in
Pane 2, and run `cmake --build build/ 2>&1 | tee build.log` in Pane 3.

---

## 7. Plugin Reference

### tmux-sensible
Applies a set of universally agreed-upon baseline options (UTF-8, larger
scrollback, `xterm-keys`, etc.). Acts as a compatibility layer.

### vim-tmux-navigator
Unifies pane navigation between Neovim splits and tmux panes.
Pressing `C-h/j/k/l` from inside Neovim navigates to the adjacent tmux pane
if there is no Neovim split in that direction, and vice versa.

**Requires setup in Neovim** — see [§ 8](#8-neovim-integration).

### tmux-resurrect
Saves the complete tmux environment to disk (sessions, windows, pane layout,
running commands, working directories). Restore manually with `<prefix> C-r`.

**Key saves:**
- Session and window names
- Pane layout
- Current working directory per pane
- Neovim state (via `@resurrect-strategy-nvim`)
- Extra processes defined in `@resurrect-processes`

### tmux-continuum
Wraps tmux-resurrect with automatic periodic saving (every 10 min by default)
and automatic restore on tmux server start.

### tmux-yank
Provides reliable clipboard integration that works on both Wayland (`wl-copy`)
and X11 (`xclip`). Without this plugin, yanked text stays inside tmux's internal
buffer and does not reach the system clipboard.

The config sets `@override_copy_command` to prefer `wl-copy` (Ubuntu 24 default
is Wayland) and fall back to `xclip` silently.

### tmux-open
In copy-mode, after selecting a URL or file path:
- `o` — opens with `xdg-open` (browser for URLs, file manager for paths)
- `C-o` — opens in Neovim directly

---

## 8. Neovim Integration

### vim-tmux-navigator

Add to your Neovim config (`lazy.nvim` example):

```lua
{
  "christoomey/vim-tmux-navigator",
  cmd = {
    "TmuxNavigateLeft", "TmuxNavigateDown",
    "TmuxNavigateUp",   "TmuxNavigateRight",
    "TmuxNavigatePrevious",
  },
  keys = {
    { "<c-h>", "<cmd>TmuxNavigateLeft<cr>" },
    { "<c-j>", "<cmd>TmuxNavigateDown<cr>" },
    { "<c-k>", "<cmd>TmuxNavigateUp<cr>" },
    { "<c-l>", "<cmd>TmuxNavigateRight<cr>" },
    { "<c-\\>", "<cmd>TmuxNavigatePrevious<cr>" },
  },
},
```

### vim-obsession (for full session restore)

This unlocks `@resurrect-strategy-nvim 'session'` — restoring open C++ buffers,
split layouts, cursor positions, and folds across reboots.

```lua
-- lazy.nvim
{ "tpope/vim-obsession" },
```

**One-time setup per project:**

```vim
:Obsession          " starts recording — creates Session.vim in cwd
:Obsession!         " stop recording (toggle)
```

After this, tmux-resurrect will call `:source Session.vim` when restoring Neovim.
Run `:Obsession` once per project root and never think about it again.

**Without vim-obsession**, change the resurrect strategy in `tmux.conf`:

```tmux
set -g @resurrect-strategy-nvim 'file'   # restores open files only
```

### Undercurl in Neovim

The config already sets the correct terminal overrides. In Neovim, enable
undercurl for LSP diagnostics:

```lua
vim.diagnostic.config({
  underline = true,
  -- ...
})
```

Theme-level undercurl (example for TokyoNight):
```lua
require("tokyonight").setup({
  on_highlights = function(hl, c)
    hl.DiagnosticUnderlineError = { undercurl = true, sp = c.error }
    hl.DiagnosticUnderlineWarn  = { undercurl = true, sp = c.warning }
  end,
})
```

---

## 9. Clipboard Integration

Ubuntu 24 LTS defaults to a Wayland session. The clipboard chain in this config:

```
tmux-yank yank action
    │
    ├─▶  wl-copy   (Wayland session — primary path)
    │
    └─▶  xclip -selection clipboard   (X11 fallback)
```

**Verify your session type:**
```bash
echo $XDG_SESSION_TYPE   # wayland or x11
```

**Install the correct backend (Arch):**
```bash
# Wayland — primary (Niri / Hyprland sessions)
sudo pacman -S wl-clipboard
wl-paste --version      # verify

# X11 — fallback
sudo pacman -S xclip
xclip -version          # verify
```

**Test clipboard from tmux:**
1. Enter copy-mode: `<prefix> [`
2. Select text with `v` then `y`
3. Outside tmux: `Ctrl+V` in any GUI app should paste

---

## 10. Nested tmux / SSH Passthrough

When you SSH into a remote machine that also runs tmux, you end up with two
tmux layers. By default, your local tmux intercepts every keybinding before
the remote sees it.

**The F12 toggle** suspends all local tmux bindings. The status bar dims to
grey to indicate you are in passthrough mode. Every keystroke, including `C-a`,
reaches the remote tmux directly.

```
Normal mode:   Full-color status bar  —  local tmux handles all binds
Passthrough:   Grey status bar        —  remote tmux handles all binds
```

**Workflow:**
```
# SSH into remote and start tmux there
ssh user@server
tmux new-session

# Now press F12 on your LOCAL machine
# Status bar goes grey — you're now controlling the remote tmux
# Use C-a normally to control the remote session

# Press F12 again to return to local control
```

**Tip:** Nest as many layers as you need. Each machine needs its own F12 toggle,
or choose a unique prefix for the remote (`C-b` instead of `C-a`) so the outer
layer intercepts `C-a` and lets `C-b` through to the inner layer.

---

## 11. Session Persistence Guide

### How it works

1. `tmux-continuum` saves the full tmux state to `~/.local/share/tmux/resurrect/`
   every 10 minutes.
2. On next tmux server start, `@continuum-restore 'on'` automatically loads the
   last saved state.
3. `tmux-resurrect` rebuilds sessions, windows, pane layouts, and working
   directories.
4. If Neovim was open and `vim-obsession` is active, tmux-resurrect re-launches
   Neovim and calls `:source Session.vim`.

### Manual controls

| Action | Binding |
|--------|---------|
| Save now | `<prefix> C-s` |
| Restore last save | `<prefix> C-r` |

### What is NOT restored

- Process state (a running `make` will be re-launched as a new shell, not resumed)
- Remote SSH sessions (tmux-resurrect will try; the SSH connection itself will fail)
- Neovim state without vim-obsession (only file names, not splits/cursor/folds)

### Resurrect save location

```bash
ls ~/.local/share/tmux/resurrect/
# tmux_resurrect_YYYY-MM-DDThh:mm:ss.txt
# last   (symlink to most recent save)
```

---

## 12. C++ Workflow Patterns

### Multi-stage build monitor

```bash
# Pane 1: Neovim (editor)
nvim src/main.cpp

# C-a | (split right)
# Pane 2: build watcher
watch -n 2 'cmake --build build/ 2>&1 | tail -20'

# C-a - (split below Pane 2)
# Pane 3: test runner
./build/tests --gtest_filter="Parser*" -v
```

Apply `<prefix> D` to get this three-pane layout instantly.

### Parallel compilation across machines

```bash
# Open a window with enough panes for each host
# C-a S   (enable pane sync)
# Now type in one pane — all receive it:
make -j$(nproc) 2>&1 | tee build-$(hostname).log
# C-a S   (disable sync when done)
```

### Quick scratch without leaving the editor

`<prefix> ~` opens the scratch session in a popup.
Run a quick command, close the popup (`exit` or `C-d`), and return exactly
where you left off in Neovim — no window switch needed.

### Searching build output

After a long build in a pane:
1. `<prefix> [` — enter copy-mode
2. `<prefix> /` — enter copy-mode with search active
3. Type `error:` or `undefined reference` and press Enter
4. `n` to jump between matches

---

## 13. Troubleshooting

### Icons show as squares or question marks

The status bar uses Nerd Font glyphs. Install a Nerd Font and configure your
terminal emulator to use it. JetBrainsMono Nerd Font is recommended for C++.

```bash
# Download from https://www.nerdfonts.com/font-downloads
# Extract to ~/.local/share/fonts/
fc-cache -fv
```

### Colors look wrong / 256 colors only

Verify `$TERM` inside tmux:
```bash
echo $TERM          # should be: tmux-256color
echo $COLORTERM     # should be: truecolor
```

If colors are wrong in your terminal but correct inside tmux, the issue is
your terminal emulator's color profile, not this config.

### vim-tmux-navigator not working

Ensure the plugin is installed in both tmux (via TPM) and Neovim. Check that
`C-h` is not bound elsewhere in Neovim (common conflict with `<BS>` in terminal
mode). Test with `:checkhealth vim-tmux-navigator` if available.

### wl-copy not found / clipboard not working

```bash
which wl-copy       # should return a path
echo $WAYLAND_DISPLAY   # should be set (e.g. wayland-0)
```

If empty, you are in an X11 session. The config automatically falls back to
`xclip`. Install it with `sudo apt install xclip`.

### tmux-resurrect restores Neovim as a blank buffer

This means `vim-obsession` is not installed or `:Obsession` was never run in
that project. Either install vim-obsession (recommended) or change the strategy:

```tmux
set -g @resurrect-strategy-nvim 'file'
```

Then `<prefix> r` to reload.

### Popup windows don't appear (fzf picker does nothing)

fzf must be installed system-wide:
```bash
which fzf           # must return a path
fzf --version       # must be >= 0.30
sudo apt install fzf
```

### Slow status bar (lag every 5 seconds)

The git branch check (`git symbolic-ref`) can be slow in large monorepos or
over network filesystems. Increase the interval or comment out the git segment:

```tmux
set -g status-interval 15     # increase from 5
```

Or remove the `#(cd ... && git ...)` portion of `status-right`.

### F12 nested tmux not restoring

If pressing F12 a second time does not restore the status bar, the `set -u`
commands failed silently (usually a version issue). Reload config manually:

```bash
<prefix> r
```

---

---

## Platform Migration Note

This config was first written targeting Ubuntu 24 LTS and has been fully
ported to **Arch Linux** as of v4.0. Every change made during migration:

| What changed | Ubuntu (old) | Arch (current) |
|---|---|---|
| Package manager | `apt` | `pacman` / `yay` |
| Clipboard command | `wl-copy` (same binary, different package) | `wl-clipboard` via pacman |
| tmux version floor | 3.3a (apt-pinned) | Latest rolling release |
| Nerd Font install | Manual `.zip` download | `ttf-jetbrains-mono-nerd` via pacman |
| `$WAYLAND_DISPLAY` | Set by GDM | Set by Niri / Hyprland session |
| Terminal | Any | WezTerm (configured in `~/.config/wezterm/wezterm.lua`) |
| Compositor | GNOME (Wayland) | Niri primary · Hyprland secondary |

No Ubuntu-specific paths, `snap` packages, or `apt`-only assumptions remain
in `tmux.conf` or this documentation.

---

*Config   → `~/.config/tmux/tmux.conf`*
*Docs     → `~/.config/tmux/TMUX_DOCS.md`*
*Author   → Matthews Mikondo (fork) · Ax-intl · Zambia*
*Brand    → Lord Mathews Termdom*
