<div align="center">

```
████████╗███╗   ███╗██╗   ██╗██╗  ██╗
   ██╔══╝████╗ ████║██║   ██║╚██╗██╔╝
   ██║   ██╔████╔██║██║   ██║ ╚███╔╝
   ██║   ██║╚██╔╝██║██║   ██║ ██╔██╗
   ██║   ██║ ╚═╝ ██║╚██████╔╝██╔╝ ██╗
   ╚═╝   ╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═╝
```

# Lord Mathews Termdom — tmux Config

**A god-tier tmux configuration built for Arch Linux, Neovim, and C++ systems programming.**

[![Arch Linux](https://img.shields.io/badge/Arch_Linux-1793D1?style=flat-square&logo=arch-linux&logoColor=white)](https://archlinux.org)
[![tmux](https://img.shields.io/badge/tmux-≥_3.3-1BB91F?style=flat-square&logo=tmux&logoColor=white)](https://github.com/tmux/tmux)
[![Neovim](https://img.shields.io/badge/Neovim-LazyVim-57A143?style=flat-square&logo=neovim&logoColor=white)](https://neovim.io)
[![Wayland](https://img.shields.io/badge/Wayland-native-F5A623?style=flat-square)](https://wayland.freedesktop.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue?style=flat-square)](LICENSE)

</div>

---

## About

This is the personal tmux configuration of **Matthews Mikondo (Matias)** —
CS student at Copperbelt University, Zambia, and founder of **Ax-intl Tech Support**.

Built for a daily workflow that lives entirely in the terminal:
C++ and systems programming in Neovim, compiler pipelines, multi-session
project management, and SSH into remote machines — all without ever reaching
for a mouse or leaving the keyboard.

> **Migrated from Ubuntu 24 LTS → Arch Linux.**
> This config is fully Arch-native. All package references, clipboard commands,
> and Wayland paths are verified against the Arch package set.

---

## Environment

| Layer | Tool |
|---|---|
| **OS** | Arch Linux (rolling) — daily driver |
| **Compositor** | Niri (primary) · Hyprland (secondary) |
| **Terminal** | WezTerm |
| **Editor** | LazyVim (Neovim) |
| **Shell** | Zsh + Powerlevel10k |
| **Theme** | Catppuccin Mocha · Mauve/Lavender dual-accent |
| **Languages** | C++ · C · Rust · Assembly · Kotlin |
| **Build** | CMake · Ninja · Make |

---

## Features

### Status Bar
Live system metrics visible at a glance — no extra plugins, just fast shell calls:

```
 󰣐 main  │  3w 2p  │   󰊤 feat/parser  │  0.45 │  3.1G │  Wed 15 Oct │  14:23
```

| Segment | Content |
|---|---|
| `󰣐 main` | Session name (flips to `⌨ PREFIX` when leader is held) |
| `3w 2p` | Window and pane count |
| `󰊤 feat/parser` | Git branch of the current pane's working directory |
| `0.45` | 1-minute load average from `/proc/loadavg` |
| `3.1G` | RAM currently in use via `free -h` |
| `Wed 15 Oct` | Weekday and date |
| `14:23` | Current time |

### Popup Utilities

| Binding | What it does |
|---|---|
| `C-a ~` | Floating scratch terminal (persists across closes) |
| `C-a C-s` | FZF session switcher with window counts |
| `C-a C-w` | FZF window finder across **all** sessions |
| `C-a D` | Instant 3-pane dev layout (editor · terminal · build) |

**Dev layout** (`C-a D`):
```
┌─────────────────────────┬───────────────┐
│                         │               │
│   Pane 1 — Editor       │  Pane 2       │
│   (Neovim · 65%)        │  Shell        │
│                         │               │
│                         ├───────────────┤
│                         │  Pane 3       │
│                         │  Build output │
└─────────────────────────┴───────────────┘
```

### Vim-style Copy Mode
Word boundaries tuned for C++ — stops correctly on identifiers, template
brackets `<>`, pointer/reference operators `*&`, and path separators:

| Key | Action |
|---|---|
| `v` | Character selection |
| `V` | Line selection |
| `C-v` | Block / column selection |
| `y` | Yank to system clipboard |
| `Y` | Yank entire line |
| `D` | Yank to end of line |

### SSH Passthrough (`F12`)
Suspends **all** local tmux bindings so every keystroke reaches an inner
(remote) tmux session unmodified. Status bar dims to grey to signal the mode.
`F12` again restores local control.

### Session Persistence
`tmux-resurrect` + `tmux-continuum` auto-save the full session state every
10 minutes and restore it on next tmux start — surviving reboots with sessions,
windows, pane layouts, and Neovim buffers intact.

---

## Key Bindings Quick Reference

> Prefix: **`C-a`** (Ctrl + a)

### Sessions & Windows

| Binding | Action |
|---|---|
| `C-a N` | New named session |
| `C-a c` | New window at current path |
| `C-a Tab` | Toggle last active window |
| `C-a C-h / C-l` | Previous / next window |
| `C-a < / >` | Swap window left / right |
| `C-a Q` | Kill server (with confirmation) |

### Panes

| Binding | Action |
|---|---|
| `C-a \|` | Split right (keeps cwd) |
| `C-a -` | Split below (keeps cwd) |
| `C-a f` | Toggle zoom |
| `C-a H/J/K/L` | Resize pane (repeatable) |
| `C-a S` | Toggle pane sync (broadcast input) |
| `C-a m` | Toggle mouse |
| `C-a x` | Kill pane |

### Navigation (no prefix — via vim-tmux-navigator)

| Binding | Action |
|---|---|
| `C-h/j/k/l` | Move between tmux panes **and** Neovim splits |
| `C-\` | Previous pane / split |

### Utility

| Binding | Action |
|---|---|
| `C-a r` | Reload config |
| `C-a e` | Edit config in Neovim |
| `C-a C-l` | Clear screen + full scrollback history |
| `C-a /` | Copy-mode with backward search active |
| `C-a u` | Copy-mode at top of history |
| `F12` | SSH passthrough toggle |

---

## Prerequisites

```bash
# Core
sudo pacman -S tmux fzf

# Clipboard (Wayland-native — Niri / Hyprland)
sudo pacman -S wl-clipboard

# Nerd Font (for status bar glyphs)
sudo pacman -S ttf-jetbrains-mono-nerd

# TPM (tmux plugin manager)
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

> **tmux ≥ 3.3** is required for `pane-border-lines`, `pane-border-indicators`,
> and `display-popup` features. Arch repos ship the latest version.

---

## Installation

```bash
# 1. Clone this repo
git clone https://github.com/<your-username>/tmux-config ~/.config/tmux

# 2. Start tmux
tmux

# 3. Install plugins
#    Inside tmux:  C-a I  (capital I)
#    Wait for "Done!" in the status bar

# 4. Reload config
#    C-a r
```

---

## Neovim Integration

### vim-tmux-navigator

Seamless pane/split navigation. Add to your `lazy.nvim` config:

```lua
{
  "christoomey/vim-tmux-navigator",
  keys = {
    { "<c-h>", "<cmd>TmuxNavigateLeft<cr>" },
    { "<c-j>", "<cmd>TmuxNavigateDown<cr>" },
    { "<c-k>", "<cmd>TmuxNavigateUp<cr>" },
    { "<c-l>", "<cmd>TmuxNavigateRight<cr>" },
    { "<c-\\>", "<cmd>TmuxNavigatePrevious<cr>" },
  },
},
```

### vim-obsession (full session restore)

Unlocks `@resurrect-strategy-nvim 'session'` — restores open buffers,
split layouts, cursor positions, and folds across reboots.

```lua
{ "tpope/vim-obsession" }
```

Run `:Obsession` once per project root to start recording. That's it.

> Without `vim-obsession`, change the resurrect strategy to `'file'`
> (restores open filenames only, no layout).

---

## Clipboard

The config auto-detects the session type:

```
tmux-yank
  │
  ├─▶  wl-copy    (Wayland — Niri/Hyprland sessions)
  └─▶  xclip      (X11 fallback)
```

Verify your session:
```bash
echo $XDG_SESSION_TYPE    # wayland  or  x11
echo $WAYLAND_DISPLAY     # e.g. wayland-0
```

---

## Plugins

| Plugin | Purpose |
|---|---|
| `tmux-plugins/tpm` | Plugin manager |
| `tmux-plugins/tmux-sensible` | Sane baseline defaults |
| `christoomey/vim-tmux-navigator` | Neovim ↔ tmux unified navigation |
| `tmux-plugins/tmux-resurrect` | Persist sessions across reboots |
| `tmux-plugins/tmux-continuum` | Auto-save every 10 minutes |
| `tmux-plugins/tmux-yank` | Wayland/X11 clipboard bridge |
| `tmux-plugins/tmux-open` | Open URLs and files from copy-mode |

---

## Troubleshooting

**Icons show as boxes** — Install a Nerd Font and set it in WezTerm:
```lua
-- wezterm.lua
config.font = wezterm.font("JetBrainsMono Nerd Font")
```

**Clipboard not working** — Confirm `wl-copy` is on `$PATH` and
`$WAYLAND_DISPLAY` is set. If in an X11 session, `xclip` is used automatically.

**Neovim restores as blank buffer** — `vim-obsession` is not installed,
or `:Obsession` was never run in that project. See Neovim Integration above.

**FZF pickers do nothing** — Run `which fzf` to confirm it is installed and on `$PATH`.

**Slow status bar** — The git branch check can be slow in very large repos.
Increase `status-interval` or comment out the `#(cd ... && git ...)` segment.

---

<div align="center">

**Matthews Mikondo (Matias)**
Copperbelt University · Zambia · Ax-intl Tech Support

*"Lord Mathews Termdom — a fully personalized terminal kingdom."*

</div>
