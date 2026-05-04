# Termdom

A curated collection of dotfiles, terminal configurations, and custom shell scripts tailored for a high-performance, minimalist Linux workflow. 

##  Repository Structure

This repository manages configurations for my core development environment:

* **`wezterm/`**: Core configuration (`wezterm.lua`) for the WezTerm terminal emulator.
* **`nvim/`**: Neovim autocommands (`autocmds.lua`) designed to seamlessly integrate with my primary text editing workflow.
* **`zsh/`**: Core Zsh environment settings and aliases (`termdom.zsh`).
* **`fastfetch/`**: Custom layout and configuration (`config.jsonc`) for terminal system information.
* **`niri/`**: Configuration additions (`config_additions.kdl`) for the Niri scrollable tiling window manager.
* **`scripts/`**: Executable Zsh utilities for daily workflow automation:
  * `theme-toggle.zsh`: Quick theme switching across the system.
  * `picker.zsh`: Fast fuzzy-selection utility.
  * `clog.zsh`: Custom logging/terminal utility.       
##  Installation

An automated installation script is included to help set up these configurations on a fresh Linux environment.

1. Clone the repository:
   ```bash
   git clone [https://github.com/Matmik1001/Termdom.git](https://github.com/Matmik1001/Termdom.git)
   cd Termdom

    Make the installer executable and run it:
    Bash

    chmod +x install.zsh
    ./install.zsh

🛠️ Tech Stack

    OS: Linux (Ubuntu/Debian and other linux distros)

    Terminal: WezTerm

    Editor: Neovim

    Shell: Zsh

Maintained by Mathews Mikondo
