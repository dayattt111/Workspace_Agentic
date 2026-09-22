# Ai Agent Workspace

# Aktifkan kontrol mouse penuh (klik pindah pane, scroll, drag resize border)
set -g mouse on

# Warna 256 agar tema Micro & Yazi tidak pudar
set -g default-terminal "screen-256color"
set -ga terminal-overrides ",*256col*:Tc"

# Status bar minimalis di bawah
set -g status-style bg=black,fg=white
set -g status-left "[#S] "
set -g status-right "%H:%M "

# Micro Settings
{
  "autosu": true,
  "clipboard": "terminal",
  "cursorline": true,
  "mkparents": true,
  "mouse": true,
  "rmtrailingws": true,
  "savecursor": true,
  "saveundo": true,
  "scrollbar": true,
  "tabsize": 2,
  "tabstospaces": true
}

# Connect w System
```
mkdir -p ~/.config/micro
ln -sf /home/hikaruu/gasken_workspace/micro-settings.json ~/.config/micro/settings.json
```

# Change Mod
chmod +x gasken.sh

# Load

# --- GASKEN WORKSPACE CONFIG ---
export EDITOR="micro"
export VISUAL="micro"
alias gasken="/home/hikaruu/gasken_workspace/gasken.sh"
# -------------------------------

# Muat ulang konfigurasi bash
source ~/.bashrc
