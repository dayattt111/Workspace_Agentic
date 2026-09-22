#!/bin/bash

BASE_DIR="/home/hikaruu/gasken_workspace"
DIR_NAME=$(basename "$PWD")
SESSION_NAME="gasken-${DIR_NAME//./-}"
CONFIG_TMUX="$BASE_DIR/config/tmux.conf"

export EDITOR="nano"
export VISUAL="nano"

# Jika sesi sudah ada, langsung attach kembali
if tmux -f "$CONFIG_TMUX" has-session -t "$SESSION_NAME" 2>/dev/null; then
  tmux -f "$CONFIG_TMUX" attach-session -t "$SESSION_NAME"
  exit 0
fi

# Ambil dimensi terminal aktif
WIN_COLS=$(tput cols 2>/dev/null || echo 160)
WIN_LINES=$(tput lines 2>/dev/null || echo 40)

RIGHT_COLS=$(( WIN_COLS * 60 / 100 ))
BOTTOM_LINES=$(( WIN_LINES * 35 / 100 ))

# 1. Buka sesi pane kiri (Pane 0 - AI Agent)
tmux -f "$CONFIG_TMUX" new-session -d -s "$SESSION_NAME" -x "$WIN_COLS" -y "$WIN_LINES" -c "$PWD"
sleep 0.25

# 2. Belah sisi kanan (Pane 1 - Yazi)
tmux -f "$CONFIG_TMUX" split-window -h -l "$RIGHT_COLS" -c "$PWD"
sleep 0.25

# 3. Belah kanan bawah (Pane 2 - Git Runner)
tmux -f "$CONFIG_TMUX" split-window -v -l "$BOTTOM_LINES" -c "$PWD"
sleep 0.25

# 4. Kirim skrip ke masing-masing pane secara halus
tmux -f "$CONFIG_TMUX" send-keys -t "$SESSION_NAME:0.0" "$BASE_DIR/panes/pane-hermes.sh" C-m
sleep 0.2

tmux -f "$CONFIG_TMUX" send-keys -t "$SESSION_NAME:0.1" "$BASE_DIR/panes/pane-yazi.sh" C-m
sleep 0.2

tmux -f "$CONFIG_TMUX" send-keys -t "$SESSION_NAME:0.2" "$BASE_DIR/panes/pane-git.sh" C-m
sleep 0.2

# 5. Arahkan kursor aktif ke Pane Git kanan bawah
tmux -f "$CONFIG_TMUX" select-pane -t "$SESSION_NAME:0.2"

# Masuk ke sesi
tmux -f "$CONFIG_TMUX" attach-session -t "$SESSION_NAME"
