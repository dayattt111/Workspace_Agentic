#!/bin/bash

# ==============================================================================
# GaskenLE - Smart AI Agent & Router Launcher (Pane 0)
# Skema: 9router (Gateway LLM Host) <───> Hermes Agent (Docker) <───> GaskenLE
# Menjaga isolasi keamanan sandbox di direktori proyek aktif ($PWD)
# ==============================================================================

# Tangkap direktori proyek aktif tempat pengguna memanggil gasken
CURRENT_PROJECT_DIR="$PWD"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# 1. Muat .env secara privat & aman (Zero-Touch Policy)
if [ -f "$WORKSPACE_DIR/.env" ]; then
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

# Variabel Lingkungan & Port
HERMES_DIR="${HERMES_DIR:-$WORKSPACE_DIR/hermes}"
HERMES_CONTAINER="${HERMES_CONTAINER_NAME:-gasken-hermes}"
HERMES_PORT="${HERMES_PORT:-6666}"
HERMES_MODEL="${HERMES_MODEL:-dev-architect-hikaruu}"

NINEROUTER_DIR="${CUSTOM_NINEROUTER_DIR:-$WORKSPACE_DIR/9router}"
NINEROUTER_PORT="${NINEROUTER_PORT:-20128}"
NINEROUTER_HOST="${NINEROUTER_HOST:-0.0.0.0}"

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

is_9router_running() {
  if command -v ss &>/dev/null; then
    ss -tulpn | grep -q ":${NINEROUTER_PORT} " && return 0
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

  echo -e "${YELLOW}[9router]${RESET} Menyalakan 9router Gateway di background..."
  mkdir -p "$WORKSPACE_DIR/logs"

  if command -v 9router &>/dev/null; then
    (
      cd "$NINEROUTER_DIR" 2>/dev/null || cd "$WORKSPACE_DIR"
      nohup 9router -p "$NINEROUTER_PORT" -H "$NINEROUTER_HOST" -n --skip-update < /dev/null > "$WORKSPACE_DIR/logs/9router.log" 2>&1 &
    )
    # Tunggu beberapa detik sampai server siap
    for _ in {1..10}; do
      sleep 0.5
      if is_9router_running; then
        echo -e "${GREEN}✓ 9router Gateway berhasil aktif di port :${NINEROUTER_PORT}${RESET}"
        return 0
      fi
    done
    echo -e "${YELLOW}ℹ 9router sedang proses booting, log: logs/9router.log${RESET}"
    return 0
  else
    echo -e "${RED}CLI '9router' belum terpasang di sistem host.${RESET}"
    echo -e "${GRAY}Pasang via: bun add -g 9router ATAU npm install -g 9router${RESET}"
    return 1
  fi
}

configure_hermes_endpoint() {
  local container="$1"
  # Set base_url dan provider hermes agar langsung tersambung ke 9router (127.0.0.1:20128)
  docker exec "$container" /opt/hermes/bin/hermes config set model.provider custom &>/dev/null || true
  docker exec "$container" /opt/hermes/bin/hermes config set model.base_url "http://127.0.0.1:${NINEROUTER_PORT}/v1" &>/dev/null || true
  
  local active_key="${NINEROUTER_API_KEY:-${OPENAI_API_KEY:-}}"
  if [ -n "$active_key" ]; then
    docker exec "$container" /opt/hermes/bin/hermes config set model.api_key "$active_key" &>/dev/null || true
  fi

  if [ -n "$HERMES_MODEL" ]; then
    docker exec "$container" /opt/hermes/bin/hermes config set model.default "$HERMES_MODEL" &>/dev/null || true
  fi
}

print_banner() {
  # Tahap 1: Intro Cepat CLI "Hermes Agent"
  clear
  echo -e "\n${CYAN}╭───────────────────────────────────────────────╮${RESET}"
  echo -e "${CYAN}│        ⚡  NOUS HERMES AGENT CLI  ⚡          │${RESET}"
  echo -e "${CYAN}│     Autonomous Pair Programmer & Gateway      │${RESET}"
  echo -e "${CYAN}╰───────────────────────────────────────────────╯${RESET}"
  sleep 0.25

  # Tahap 2: Animasi Slide Top-to-Bottom Logo Maskot Emas & Workspace
  clear
  echo -e "${GOLD}"
  local logo_lines=(
    "              -:*=:-:-:                    "
    "             .**%%%%%=#=.               :-*"
    "     .=**+=+*##@@@%#%%*##*+--        -*++%:"
    "   :+*#@@@@@@##*+==--::.:--:-+=  -+*=:.:%- "
    "    +=%@@@%#+=:...:=**###%%%%%#*=:..:=*#  "
    "    *=%@@**-....=%#+-::--=*#*:...:+%%*+#   "
    ":-:=+%@@#+....-%*=::::=++=-.-===+=-..=*-   "
    "%-#%@@@%*....-%=-::=+=------::--==+#%.     "
    "%=@@@@@%:....#*-:-*--+=.::-==-:::-==.      "
    "==**#@%%:....*#=--%-#:+*+++++*##=:         "
    "   =+@@*+....:%#=***:#**++*%**=            "
    "   .**@%*=....-%%#*+*==-=+*=-=++           "
    "  -#+@@@@**=:...:=*#%%%#####*##:           "
    "   .=*##**###*=-:.....::::-=+-             "
    "     .+=--==*+@%%%%*++**+=:                "
    "            -*+****+**=:                   "
    "             =++++++-.                     "
  )

  for line in "${logo_lines[@]}"; do
    echo "$line"
    sleep 0.012
  done

  echo -e "${RESET}"
  local title_lines=(
    "   ___           _              _     ___ "
    "  / __|__ _  ___| |_____ _ _   | |   | __|"
    " | (_ / _\` |(_-< / / -_) ' \\  | |__ | _| "
    "  \\___\\__,_|/__/_\\_\\___|_||_|  |____||___|"
  )

  for line in "${title_lines[@]}"; do
    echo -e "${GOLD}${line}${RESET}"
    sleep 0.012
  done

  echo -e "${BONE}         Workspace By hikaruu${RESET}"
  echo -e "${GOLD}===============================================${RESET}"
}

start_unified() {
  print_banner

  # 1. Pastikan 9router Gateway menyala
  ensure_9router_daemon

  # 2. Cek Docker
  if ! command -v docker &>/dev/null; then
    echo -e "${RED}Error: Docker CLI tidak ditemukan di sistem host.${RESET}"
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

  # Cek mount aktif /workspace untuk memastikan isolasi folder proyek yang tepat
  local current_mount=""
  if [ -n "$RUNNING_CONTAINER" ]; then
    current_mount=$(docker inspect "$RUNNING_CONTAINER" --format '{{range .Mounts}}{{if eq .Destination "/workspace"}}{{.Source}}{{end}}{{end}}' 2>/dev/null)
  fi

  # Jika container belum jalan atau folder mount berbeda dari CURRENT_PROJECT_DIR, sesuaikan mount
  if [ -z "$RUNNING_CONTAINER" ] || [ "$current_mount" != "$CURRENT_PROJECT_DIR" ]; then
    echo -e "${YELLOW}[Hermes]${RESET} Mengisolasi sandbox agent ke proyek: ${GOLD}$CURRENT_PROJECT_DIR${RESET}..."
    PROJECT_DIR="$CURRENT_PROJECT_DIR" docker compose up -d
    sleep 1
    RUNNING_CONTAINER=$(docker ps --filter "name=$HERMES_CONTAINER" --format '{{.Names}}' | head -n 1)
  fi

  if [ -n "$RUNNING_CONTAINER" ]; then
    echo -e "${GREEN}✓ Hermes Container Aktif:${RESET} $RUNNING_CONTAINER"
    echo -e "${GRAY}Router Endpoint :${RESET} ${CYAN}http://127.0.0.1:${NINEROUTER_PORT}/v1${RESET}"
    echo -e "${GRAY}Workspace Mount :${RESET} ${GOLD}/workspace${RESET} -> $CURRENT_PROJECT_DIR (Sandbox Terisolasi)"

    # Sinkronisasi endpoint koneksi Hermes ke 9router
    configure_hermes_endpoint "$RUNNING_CONTAINER"

    echo -e "\n${BONE}▶ Membuka Interactive Hermes Agent... (Siap Prompt!)${RESET}"
    echo -e "${GRAY}Tips: Ketik /exit atau Ctrl+C untuk keluar ke menu manajemen.${RESET}\n"
    
    # LANGSUNG BUKA PROMPT HERMES AGENT DI DALAM /workspace PROYEK
    docker exec -it -w /workspace "$RUNNING_CONTAINER" /opt/hermes/bin/hermes
  else
    echo -e "${RED}Gagal menjalankan container Hermes.${RESET}"
    echo -e "${GRAY}Periksa dengan: docker compose logs di folder $HERMES_DIR${RESET}"
  fi

  hermes_post_session_menu "$RUNNING_CONTAINER"
}

hermes_post_session_menu() {
  local container="$1"
  while true; do
    echo -e "\n${GOLD}===============================================${RESET}"
    echo -e "${BONE}          ⚙️  MANAJEMEN AI AGENT & ROUTER       ${RESET}"
    echo -e "${GOLD}===============================================${RESET}"
    echo -e "  ${GOLD}1)${RESET} ${BONE}Masuk Kembali ke Prompt Hermes${RESET} ${GREEN}(Chat Agent)${RESET}"
    echo -e "  ${GOLD}2)${RESET} ${BONE}Mode TUI Modern Hermes${RESET} ${GRAY}(hermes --tui)${RESET}"
    echo -e "  ${GOLD}3)${RESET} ${BONE}Pilih / Ganti Model Hermes${RESET} ${GRAY}(hermes model)${RESET}"
    echo -e "  ${GOLD}4)${RESET} ${BONE}Setup Wizard Hermes${RESET} ${GRAY}(hermes setup)${RESET}"
    echo -e "  ${GOLD}5)${RESET} ${CYAN}Kelola 9router Gateway${RESET} ${GRAY}(Buka Web UI / Log)${RESET}"
    echo -e "  ${GOLD}6)${RESET} ${YELLOW}Terminal Shell Container${RESET} ${GRAY}(docker exec bash)${RESET}"
    echo -e "  ${GOLD}7)${RESET} ${BONE}Terminal Shell Biasa${RESET} ${GRAY}(Bash Workspace)${RESET}"
    echo ""
    read -r -p "Pilihan [1-7] (Default 1): " sub_opt
    case "$sub_opt" in
      2)
        docker exec -it -w /workspace "$container" /opt/hermes/bin/hermes --tui
        ;;
      3)
        docker exec -it -w /workspace "$container" /opt/hermes/bin/hermes model
        ;;
      4)
        docker exec -it -w /workspace "$container" /opt/hermes/bin/hermes setup
        ;;
      5)
        manage_9router_menu
        ;;
      6)
        docker exec -it -w /workspace "$container" bash || docker exec -it "$container" sh
        ;;
      7)
        start_shell
        return
        ;;
      *)
        docker exec -it -w /workspace "$container" /opt/hermes/bin/hermes
        ;;
    esac
  done
}

manage_9router_menu() {
  echo -e "\n${CYAN}--- PENGATURAN 9ROUTER GATEWAY ---${RESET}"
  echo -e "Status: $(is_9router_running && echo -e "${GREEN}AKTIF (:20128)${RESET}" || echo -e "${RED}MATI${RESET}")"
  echo -e "  ${GOLD}1)${RESET} Buka Dashboard Web UI di Browser ${GRAY}(http://localhost:20128)${RESET}"
  echo -e "  ${GOLD}2)${RESET} Pantau Streaming Log 9router ${GRAY}(tail -f logs/9router.log)${RESET}"
  echo -e "  ${GOLD}3)${RESET} Restart 9router Gateway"
  echo -e "  ${GOLD}4)${RESET} Kembali"
  read -r -p "Pilihan [1-4] (Default 1): " nr_act
  case "$nr_act" in
    1)
      if command -v xdg-open &>/dev/null; then
        xdg-open "http://localhost:${NINEROUTER_PORT}" &>/dev/null &
      fi
      echo -e "${GREEN}Dashboard:${RESET} http://localhost:${NINEROUTER_PORT}"
      ;;
    2)
      echo -e "${GRAY}Menampilkan log 9router (Ctrl+C untuk selesai)...${RESET}"
      tail -f -n 50 "$WORKSPACE_DIR/logs/9router.log"
      ;;
    3)
      echo -e "${YELLOW}Merestart 9router...${RESET}"
      pkill -f "9router" 2>/dev/null || true
      sleep 1
      ensure_9router_daemon
      ;;
    *)
      ;;
  esac
}

start_9router_standalone() {
  clear
  echo -e "${CYAN}===============================================${RESET}"
  echo -e "${BONE}       🌐 9ROUTER GATEWAY CONSOLE LOG          ${RESET}"
  echo -e "${CYAN}===============================================${RESET}"
  
  if [ ! -d "$NINEROUTER_DIR" ]; then
    mkdir -p "$NINEROUTER_DIR"
  fi

  cd "$NINEROUTER_DIR" || exit 1

  if command -v 9router &>/dev/null; then
    echo -e "${GRAY}Menjalankan server 9router di foreground (Ctrl+C untuk keluar)...${RESET}\n"
    9router -p "$NINEROUTER_PORT" -H "$NINEROUTER_HOST" -l
  else
    echo -e "${RED}CLI '9router' belum terpasang.${RESET}"
    echo -e "Pasang dengan: ${GOLD}bun add -g 9router${RESET} atau ${GOLD}npm install -g 9router${RESET}"
  fi

  start_shell
}

start_shell() {
  echo -e "\n${GRAY}Memuat shell terminal GaskenLE...${RESET}"
  cd "$CURRENT_PROJECT_DIR" || true
  bash --rcfile "$WORKSPACE_DIR/config/workspace-bashrc" -i
}

# Evaluasi Mode Eksekusi Awal
case "$DEFAULT_AGENT" in
  "unified")
    start_unified
    ;;
  "9router")
    start_9router_standalone
    ;;
  "shell")
    start_shell
    ;;
  *)
    print_banner
    echo -e "${GRAY}Ruang Kerja Aktif :${RESET} ${GOLD}$CURRENT_PROJECT_DIR${RESET}\n"
    echo -e "${BONE}Pilih Mode AI Agent untuk Panel ini:${RESET}"
    echo -e "  ${GOLD}1)${RESET} ${BONE}Unified Mode${RESET} ${GREEN}(Langsung Siap Prompt Hermes Agent!)${RESET} ${GRAY}[Default]${RESET}"
    echo -e "  ${GOLD}2)${RESET} ${CYAN}9router Gateway Console${RESET} ${GRAY}(Live Logs & Server Status)${RESET}"
    echo -e "  ${GOLD}3)${RESET} ${YELLOW}Terminal Shell Container${RESET} ${GRAY}(Bash di /workspace proyek)${RESET}"
    echo -e "  ${GOLD}4)${RESET} ${BONE}Terminal Shell Biasa${RESET} ${GRAY}(Bash Workspace)${RESET}"
    echo ""
    read -r -p "Pilihan [1-4] (Default 1): " choice
    case "$choice" in
      2) start_9router_standalone ;;
      3)
        RUNNING_CONTAINER=$(docker ps --filter "name=$HERMES_CONTAINER" --format '{{.Names}}' | head -n 1)
        if [ -n "$RUNNING_CONTAINER" ]; then
          docker exec -it -w /workspace "$RUNNING_CONTAINER" bash
        else
          start_unified
        fi
        start_shell
        ;;
      4) start_shell ;;
      *) start_unified ;;
    esac
    ;;
esac
