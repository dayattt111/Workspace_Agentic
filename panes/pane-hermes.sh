#!/bin/bash

# ==============================================================================
# GaskenLE - Smart AI Agent & Router Launcher (Pane 0)
# Skema: 9router (Gateway LLM) <---> Hermes Agent (Docker) <---> GaskenLE
# Konfigurasi dinamis & privat dimuat dari .env dan config/agent.conf
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# 1. Muat .env jika ada (Privat & Prioritas Tertinggi)
if [ -f "$WORKSPACE_DIR/.env" ]; then
  # Gunakan set -a untuk mengekspor variable tanpa mencetak isinya
  set -a
  # shellcheck source=/dev/null
  source "$WORKSPACE_DIR/.env" 2>/dev/null || true
  set +a
fi

# 2. Muat config/agent.conf untuk fallback defaults
if [ -f "$WORKSPACE_DIR/config/agent.conf" ]; then
  # shellcheck source=/dev/null
  source "$WORKSPACE_DIR/config/agent.conf"
fi

# Fallback internal jika belum terdefinisi sama sekali
HERMES_DIR="${HERMES_DIR:-$WORKSPACE_DIR/hermes}"
HERMES_CONTAINER="${HERMES_CONTAINER_NAME:-gasken-hermes}"
HERMES_PORT="${HERMES_PORT:-6666}"
HERMES_MODEL="${HERMES_MODEL:-hermes-3-llama-3.1-8b}"

NINEROUTER_DIR="${CUSTOM_NINEROUTER_DIR:-$WORKSPACE_DIR/9router}"
NINEROUTER_PORT="${NINEROUTER_PORT:-20128}"
NINEROUTER_HOST="${NINEROUTER_HOST:-0.0.0.0}"
NINEROUTER_GATEWAY_URL="${NINEROUTER_GATEWAY_URL:-http://host.docker.internal:20128/v1}"

DEFAULT_AGENT="${AGENT_MODE:-menu}"

# Pastikan path bin lokal & bun tersedia
export PATH="$HOME/.bun/bin:$HOME/.local/bin:$PATH"

# Palette Warna ANSI GaskenLE
GOLD="\033[38;5;220m"
BONE="\033[38;5;254m"
GRAY="\033[38;5;244m"
GREEN="\033[38;5;114m"
YELLOW="\033[33m"
CYAN="\033[36m"
RED="\033[38;5;203m"
RESET="\033[0m"

clear
echo -e "${GOLD}===============================================${RESET}"
echo -e "${BONE}       ⚡ GASKENLE AI AGENT ECOSYSTEM ⚡       ${RESET}"
echo -e "${GRAY}      9router Gateway  <───>  Hermes Docker    ${RESET}"
echo -e "${GOLD}===============================================${RESET}"

is_9router_running() {
  if command -v ss &>/dev/null; then
    ss -tuln | grep -q ":${NINEROUTER_PORT} " && return 0
  fi
  if command -v curl &>/dev/null; then
    local code
    code=$(curl -s -o /dev/null -w "%{http_code}" "http://127.0.0.1:${NINEROUTER_PORT}/" 2>/dev/null || echo "000")
    [ "$code" != "000" ] && return 0
  fi
  return 1
}

ensure_9router_daemon() {
  if is_9router_running; then
    echo -e "${GREEN}✓ 9router Gateway aktif di port :${NINEROUTER_PORT}${RESET}"
    return 0
  fi

  echo -e "${YELLOW}[9router]${RESET} Menjalankan 9router Gateway di background..."
  mkdir -p "$WORKSPACE_DIR/logs"

  if command -v 9router &>/dev/null; then
    (
      cd "$NINEROUTER_DIR" 2>/dev/null || cd "$WORKSPACE_DIR"
      nohup 9router -p "$NINEROUTER_PORT" -H "$NINEROUTER_HOST" -n --skip-update > "$WORKSPACE_DIR/logs/9router.log" 2>&1 &
    )
    sleep 1.5
    if is_9router_running; then
      echo -e "${GREEN}✓ 9router Gateway berhasil dinyalakan (Port :${NINEROUTER_PORT})${RESET}"
      return 0
    else
      echo -e "${YELLOW}ℹ 9router sedang memulai, log: logs/9router.log${RESET}"
      return 0
    fi
  else
    echo -e "${RED}CLI '9router' belum terpasang.${RESET}"
    echo -e "${GRAY}Pasang via: bun add -g 9router ATAU npm install -g 9router${RESET}"
    return 1
  fi
}

start_unified() {
  echo -e "\n${BONE}▶ Memulai Mode Unified (9router + Hermes Agent)...${RESET}"
  
  # 1. Pastikan 9router aktif
  ensure_9router_daemon

  # 2. Pastikan Docker aktif dan jalankan Hermes
  if ! command -v docker &>/dev/null; then
    echo -e "${RED}Error: Docker tidak ditemukan di sistem host.${RESET}"
    start_shell
    return
  fi

  if [ ! -d "$HERMES_DIR" ]; then
    echo -e "${RED}Direktori Hermes tidak ditemukan di: ${HERMES_DIR}${RESET}"
    start_shell
    return
  fi

  cd "$HERMES_DIR" || exit 1

  RUNNING_CONTAINER=$(docker ps --filter "name=$HERMES_CONTAINER" --format '{{.Names}}' | head -n 1)

  if [ -z "$RUNNING_CONTAINER" ]; then
    echo -e "${YELLOW}[Hermes]${RESET} Menjalankan container Docker Hermes..."
    docker compose up -d
    sleep 1
    RUNNING_CONTAINER=$(docker ps --filter "name=$HERMES_CONTAINER" --format '{{.Names}}' | head -n 1)
  fi

  if [ -n "$RUNNING_CONTAINER" ]; then
    echo -e "${GREEN}✓ Container Hermes aktif:${RESET} $RUNNING_CONTAINER"
    echo -e "${GRAY}Endpoint 9router :${RESET} ${CYAN}${NINEROUTER_GATEWAY_URL}${RESET}"
    echo -e "${GRAY}Hermes Port      :${RESET} ${GOLD}http://127.0.0.1:${HERMES_PORT}${RESET}"
    echo -e "${BONE}Menghubungkan ke sesi shell Hermes Agent...${RESET}\n"
    docker exec -it "$RUNNING_CONTAINER" bash || docker exec -it "$RUNNING_CONTAINER" sh
  else
    echo -e "${RED}Gagal mendeteksi container Hermes yang aktif.${RESET}"
    echo -e "${GRAY}Cek log: docker compose logs di folder $HERMES_DIR${RESET}"
  fi

  start_shell
}

start_9router_standalone() {
  echo -e "\n${CYAN}[9router Gateway]${RESET} Menjalankan server gateway realtime..."
  
  if [ ! -d "$NINEROUTER_DIR" ]; then
    mkdir -p "$NINEROUTER_DIR"
  fi

  cd "$NINEROUTER_DIR" || exit 1
  echo -e "${GREEN}Direktori aktif:${RESET} $PWD"

  if command -v 9router &>/dev/null; then
    echo -e "${GRAY}Menjalankan '9router -p $NINEROUTER_PORT -l'... (Tekan Ctrl+C untuk keluar)${RESET}\n"
    9router -p "$NINEROUTER_PORT" -H "$NINEROUTER_HOST" -l
  else
    echo -e "${RED}CLI '9router' belum terdeteksi di sistem.${RESET}"
    echo -e "${BONE}Apakah ingin menginstalnya sekarang?${RESET}"
    echo -e "  ${GOLD}1)${RESET} Install via Bun: bun add -g 9router"
    echo -e "  ${GOLD}2)${RESET} Install via NPM: npm install -g 9router"
    echo -e "  ${GOLD}3)${RESET} Lewati & buka terminal shell"
    read -r -p "Pilihan [1-3]: " ins_opt
    case "$ins_opt" in
      1) bun add -g 9router ;;
      2) npm install -g 9router ;;
      *) ;;
    esac
  fi

  start_shell
}

start_hermes_standalone() {
  echo -e "\n${YELLOW}[Hermes Agent]${RESET} Manajemen Container Docker..."

  if [ ! -d "$HERMES_DIR" ]; then
    echo -e "${RED}Folder Hermes tidak ditemukan: ${HERMES_DIR}${RESET}"
    start_shell
    return
  fi

  cd "$HERMES_DIR" || exit 1

  if ! command -v docker &>/dev/null; then
    echo -e "${RED}Docker tidak terdeteksi di sistem host.${RESET}"
    start_shell
    return
  fi

  RUNNING_CONTAINER=$(docker ps --filter "name=$HERMES_CONTAINER" --format '{{.Names}}' | head -n 1)

  if [ -n "$RUNNING_CONTAINER" ]; then
    echo -e "${GREEN}✓ Container aktif:${RESET} $RUNNING_CONTAINER"
    echo -e "${BONE}Menu Aksi Hermes:${RESET}"
    echo -e "  ${GOLD}1)${RESET} Masuk Shell Container ${GRAY}(docker exec bash)${RESET}"
    echo -e "  ${GOLD}2)${RESET} Streaming Log Container ${GRAY}(docker logs -f)${RESET}"
    echo -e "  ${GOLD}3)${RESET} Restart Container ${GRAY}(docker compose restart)${RESET}"
    echo -e "  ${GOLD}4)${RESET} Terminal Shell Lokal"
    echo ""
    read -r -p "Pilihan [1-4] (Default 1): " h_act
    case "$h_act" in
      2) docker logs -f --tail 100 "$RUNNING_CONTAINER" ;;
      3) docker compose restart ;;
      4) ;;
      *) docker exec -it "$RUNNING_CONTAINER" bash || docker exec -it "$RUNNING_CONTAINER" sh ;;
    esac
  else
    echo -e "${GRAY}Container '$HERMES_CONTAINER' belum aktif.${RESET}"
    echo -e "  ${GOLD}1)${RESET} Jalankan Container ${GRAY}(docker compose up -d)${RESET}"
    echo -e "  ${GOLD}2)${RESET} Buka Terminal di folder ${HERMES_DIR}"
    read -r -p "Pilihan [1-2] (Default 1): " up_act
    if [ "$up_act" != "2" ]; then
      docker compose up -d
      sleep 1
      NEW_C=$(docker ps --filter "name=$HERMES_CONTAINER" --format '{{.Names}}' | head -n 1)
      if [ -n "$NEW_C" ]; then
        docker exec -it "$NEW_C" bash || docker exec -it "$NEW_C" sh
      fi
    fi
  fi

  start_shell
}

start_shell() {
  echo -e "\n${GRAY}Memuat shell terminal GaskenLE...${RESET}"
  bash --rcfile "$WORKSPACE_DIR/config/workspace-bashrc" -i
}

# Evaluasi Mode Eksekusi
case "$DEFAULT_AGENT" in
  "unified")
    start_unified
    ;;
  "hermes")
    start_hermes_standalone
    ;;
  "9router")
    start_9router_standalone
    ;;
  "shell")
    start_shell
    ;;
  *)
    echo -e "${BONE}Pilih Mode AI Agent untuk Panel ini:${RESET}"
    echo -e "  ${GOLD}1)${RESET} ${BONE}Unified Mode${RESET} ${GREEN}(9router + Hermes Connected)${RESET} ${GRAY}[Rekomendasi]${RESET}"
    echo -e "  ${GOLD}2)${RESET} ${CYAN}9router Gateway Server${RESET} ${GRAY}(Live Logs di Port :${NINEROUTER_PORT})${RESET}"
    echo -e "  ${GOLD}3)${RESET} ${YELLOW}Hermes Agent (Docker)${RESET} ${GRAY}(Shell Container / Log / Restart)${RESET}"
    echo -e "  ${GOLD}4)${RESET} ${BONE}Terminal Shell Biasa${RESET} ${GRAY}(Bash Workspace)${RESET}"
    echo ""
    read -r -p "Pilihan [1-4] (Default 1): " choice
    case "$choice" in
      2) start_9router_standalone ;;
      3) start_hermes_standalone ;;
      4) start_shell ;;
      *) start_unified ;;
    esac
    ;;
esac
