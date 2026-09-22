#!/bin/bash

# ==============================================================================
# GaskenLE - Smart AI Agent Launcher (Pane 0)
# Menghubungkan Hermes (Docker), 9router, atau Shell secara portabel & modular
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

CONFIG_FILE="$WORKSPACE_DIR/config/agent.conf"
if [ -f "$CONFIG_FILE" ]; then
  # shellcheck source=/dev/null
  source "$CONFIG_FILE"
fi

# Fallback default jika tidak terdefinisi di agent.conf
HERMES_DIR="${HERMES_DIR:-$HOME/hermes-agents}"
HERMES_CONTAINER="${HERMES_CONTAINER:-hermes-agent}"
NINEROUTER_DIR="${NINEROUTER_DIR:-$HOME/9router-agentic-AI}"
DEFAULT_AGENT="${DEFAULT_AGENT:-menu}"

# Pastikan path bin lokal & bun terdeteksi
export PATH="$HOME/.bun/bin:$HOME/.local/bin:$PATH"

GOLD="\033[38;5;220m"
BONE="\033[38;5;254m"
GRAY="\033[38;5;244m"
GREEN="\033[38;5;114m"
YELLOW="\033[33m"
CYAN="\033[36m"
RESET="\033[0m"

clear
echo -e "${GOLD}===============================================${RESET}"
echo -e "${BONE}          ⚡ GASKENLE AI AGENT PANE ⚡         ${RESET}"
echo -e "${GOLD}===============================================${RESET}"

start_hermes() {
  echo -e "\n${YELLOW}[Hermes Agent]${RESET} Menghubungkan ke runtime Docker..."
  
  if [ ! -d "$HERMES_DIR" ]; then
    echo -e "${GRAY}Direktori Hermes tidak ditemukan di: ${HERMES_DIR}${RESET}"
    echo -e "${GRAY}Mengalihkan ke shell terminal...${RESET}\n"
    start_shell
    return
  fi

  cd "$HERMES_DIR" || exit 1

  # Cek ketersediaan Docker CLI
  if ! command -v docker &> /dev/null; then
    echo -e "${GRAY}Docker tidak terdeteksi di sistem ini.${RESET}"
    echo -e "${GRAY}Membuka shell di folder Hermes...${RESET}\n"
    start_shell
    return
  fi

  # Cari container yang sedang berjalan
  RUNNING_CONTAINER=$(docker ps --filter "name=$HERMES_CONTAINER" --format '{{.Names}}' | head -n 1)
  
  if [ -n "$RUNNING_CONTAINER" ]; then
    echo -e "${GREEN}✓ Container '$RUNNING_CONTAINER' aktif.${RESET}"
    echo -e "${BONE}Menu Hermes:${RESET}"
    echo -e "  ${GOLD}1)${RESET} Masuk Shell Container ${GRAY}(docker exec bash)${RESET}"
    echo -e "  ${GOLD}2)${RESET} Pantau Log Realtime ${GRAY}(docker logs -f)${RESET}"
    echo -e "  ${GOLD}3)${RESET} Buka Terminal di folder ${HERMES_DIR}"
    echo ""
    read -r -p "Pilihan [1-3] (Default 1): " h_choice
    case "$h_choice" in
      2)
        echo -e "${GRAY}Menampilkan log container (Tekan Ctrl+C untuk keluar)...${RESET}"
        docker logs -f --tail 100 "$RUNNING_CONTAINER"
        start_shell
        ;;
      3)
        start_shell
        ;;
      *)
        echo -e "${GRAY}Melakukan attach ke dalam sesi container...${RESET}\n"
        docker exec -it "$RUNNING_CONTAINER" bash || docker exec -it "$RUNNING_CONTAINER" sh
        start_shell
        ;;
    esac
  else
    echo -e "${GRAY}Container '$HERMES_CONTAINER' belum aktif.${RESET}"
    if [ -f "docker-compose.yml" ] || [ -f "compose.yaml" ]; then
      echo -e "${BONE}Opsi Peluncuran:${RESET}"
      echo -e "  ${GOLD}1)${RESET} Jalankan Container ${GRAY}(docker compose up -d)${RESET}"
      echo -e "  ${GOLD}2)${RESET} Buka Terminal di folder Hermes ${GRAY}($HERMES_DIR)${RESET}"
      echo ""
      read -r -p "Pilihan [1-2] (Default 1): " up_choice
      if [ "$up_choice" = "2" ]; then
        start_shell
      else
        echo -e "${GRAY}Menjalankan 'docker compose up -d'...${RESET}"
        docker compose up -d
        sleep 1
        NEW_CONTAINER=$(docker ps --filter "name=$HERMES_CONTAINER" --format '{{.Names}}' | head -n 1)
        if [ -n "$NEW_CONTAINER" ]; then
          echo -e "${GREEN}✓ Container aktif:${RESET} $NEW_CONTAINER"
          docker exec -it "$NEW_CONTAINER" bash || docker exec -it "$NEW_CONTAINER" sh
        fi
        start_shell
      fi
    else
      echo -e "${GRAY}docker-compose.yml tidak ditemukan di ${HERMES_DIR}.${RESET}"
      start_shell
    fi
  fi
}

start_9router() {
  echo -e "\n${CYAN}[9router Agentic AI]${RESET} Membuka runtime 9router..."

  if [ ! -d "$NINEROUTER_DIR" ]; then
    echo -e "${GRAY}Direktori 9router tidak ditemukan di: ${NINEROUTER_DIR}${RESET}"
    echo -e "${GRAY}Mengalihkan ke shell terminal...${RESET}\n"
    start_shell
    return
  fi

  cd "$NINEROUTER_DIR" || exit 1
  echo -e "${GREEN}Direktori aktif:${RESET} $PWD"

  if command -v 9router &> /dev/null; then
    echo -e "${BONE}Menu 9router:${RESET}"
    echo -e "  ${GOLD}1)${RESET} Jalankan 9router Gateway Server ${GRAY}(9router -l)${RESET}"
    echo -e "  ${GOLD}2)${RESET} Buka Terminal Shell di Direktori 9router"
    echo ""
    read -r -p "Pilihan [1-2] (Default 1): " nr_choice
    if [ "$nr_choice" = "2" ]; then
      start_shell
    else
      echo -e "${GRAY}Menjalankan '9router -l'... (Tekan Ctrl+C untuk kembali ke shell)${RESET}\n"
      9router -l
      start_shell
    fi
  elif [ -f "package.json" ]; then
    echo -e "${GRAY}Tips: Tekan Ctrl+C jika ingin kembali ke shell 9router.${RESET}\n"
    if command -v bun &> /dev/null; then
      bun run dev 2>/dev/null || bun start 2>/dev/null || start_shell
    elif command -v npm &> /dev/null; then
      npm run dev 2>/dev/null || npm start 2>/dev/null || start_shell
    else
      start_shell
    fi
  else
    echo -e "${GRAY}CLI '9router' belum terdeteksi di PATH.${RESET}"
    start_shell
  fi
}

start_shell() {
  echo -e "${GRAY}Memuat shell terminal GaskenLE...${RESET}"
  bash --rcfile "$WORKSPACE_DIR/config/workspace-bashrc" -i
}

# Evaluasi Mode Eksekusi
case "$DEFAULT_AGENT" in
  "hermes")
    start_hermes
    ;;
  "9router")
    start_9router
    ;;
  "shell")
    start_shell
    ;;
  *)
    echo -e "${BONE}Pilih AI Agent Engine untuk Panel ini:${RESET}"
    echo -e "  ${GOLD}1)${RESET} ${BONE}Hermes Agent${RESET} ${GRAY}(Docker Container)${RESET}"
    echo -e "  ${GOLD}2)${RESET} ${BONE}9router Agentic AI${RESET} ${GRAY}(Gateway / CLI / Dev)${RESET}"
    echo -e "  ${GOLD}3)${RESET} ${BONE}Terminal Shell Biasa${RESET} ${GRAY}(Bash Workspace)${RESET}"
    echo ""
    read -r -p "Pilihan [1-3] (Default 1): " choice
    case "$choice" in
      2) start_9router ;;
      3) start_shell ;;
      *) start_hermes ;;
    esac
    ;;
esac
