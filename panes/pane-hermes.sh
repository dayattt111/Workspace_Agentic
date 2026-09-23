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

# ── Helper: cetak teks di tengah terminal sesuai lebar aktual ──
_cp() {
  local text="$1" color="${2:-}"
  local cols; cols=$(tput cols 2>/dev/null || echo 40)
  local len=${#text}
  local pad=$(( (cols - len) / 2 ))
  [ "$pad" -lt 0 ] && pad=0
  printf "%${pad}s" ""
  echo -e "${color}${text}${RESET}"
}

show_welcome_experience() {
  local cols; cols=$(tput cols 2>/dev/null || echo 44)
  [ -z "$cols" ] || [ "$cols" -lt 20 ] && cols=44

  # helper: cetak teks di tengah dengan warna (printf, aman untuk backslash)
  _cl() {
    local text="$1" color="${2:-}"
    local len="${#text}"
    local pad=$(( (cols - len) / 2 ))
    [ "$pad" -lt 0 ] && pad=0
    printf "%${pad}s" ""
    printf "%b%s%b\n" "$color" "$text" "$RESET"
  }

  # Stage 1: Hermes Agent Intro
  clear
  echo ""
  echo ""
  _cl "╔══════════════════════════════╗" "$CYAN"
  _cl "║                              ║" "$CYAN"
  _cl "║   H E R M E S   A G E N T   ║" "$BONE"
  _cl "║          C L I               ║" "$CYAN"
  _cl "║                              ║" "$CYAN"
  _cl "╚══════════════════════════════╝" "$CYAN"
  echo ""
  _cl "Autonomous Pair Programmer" "$GRAY"
  _cl "Nous Research · Agentic AI" "$GRAY"
  echo ""
  _cl "[ Memuat runtime...    3s ]" "$GRAY"
  sleep 1
  _cl "[ Memeriksa gateway... 2s ]" "$GRAY"
  sleep 1
  _cl "[ Konek ke sandbox...  1s ]" "$GRAY"
  sleep 1

  # Stage 2: GaskenLE mascot + title
  clear
  echo ""
  _cl "     .*****:..        " "$GOLD"
  _cl " :*###%%%%#*:*#*::.   " "$GOLD"
  _cl ".#%%%%%###*:***###**#:" "$GOLD"
  _cl ".*#%%*::#*:::***#***: " "$GOLD"
  _cl "*##%%#.*#..*.*:.#:    " "$GOLD"
  _cl "##%%%@# #:.*:.:#*::.  " "$GOLD"
  _cl "*#%%#***::******::    " "$GOLD"
  _cl ".*%#:.##*#***:::.     " "$GOLD"
  _cl ":#%%%#*:*:*#*::***:.  " "$GOLD"
  _cl " **##%##:::*::.       " "$GOLD"
  _cl "  :#####*:.           " "$GOLD"
  echo ""
  _cl "════════════════════════════════" "$GOLD"
  echo ""
  _cl "░█▀▀░█▀█░█▀▀░█░█░█▀▀░█▀█░█░░░█▀▀" "$GOLD"
  _cl "░█░█░█▀█░▀▀█░█▀▄░█▀▀░█░█░█░░░█▀▀" "$GOLD"
  _cl "░▀▀▀░▀░▀░▀▀▀░▀░▀░▀▀▀░▀░▀░▀▀▀░▀▀▀" "$GOLD"
  echo ""
  _cl "Workspace By hikaruu" "$BONE"
  _cl "════════════════════════════════" "$GOLD"
}

# Flag untuk mencegah double-cleanup
_NINEROUTER_STARTED_BY_US=0

_cleanup_9router() {
  if [ "$_NINEROUTER_STARTED_BY_US" -eq 1 ]; then
    echo -e "\n${YELLOW}[GaskenLE]${RESET} Menghentikan 9router Gateway yang dijalankan sesi ini..."
    pkill -f "9router" 2>/dev/null || true
    _NINEROUTER_STARTED_BY_US=0
  fi
}

start_unified() {
  show_welcome_experience

  # 1. Pastikan 9router Gateway menyala — lacak bila kita yang nyalain
  if ! is_9router_running; then
    ensure_9router_daemon && _NINEROUTER_STARTED_BY_US=1
  else
    echo -e "${GREEN}✓ 9router Gateway aktif di port :${NINEROUTER_PORT}${RESET}"
  fi

  # Pasang trap: matikan 9router saat sesi ditutup (EXIT / Ctrl+C / kill)
  trap '_cleanup_9router' EXIT INT TERM

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
    echo -e "\n${GOLD}═══════════════════════════════════════════════${RESET}"
    echo -e "${BONE}       ⚙  MANAJEMEN AI AGENT & ROUTER          ${RESET}"
    echo -e "${GOLD}═══════════════════════════════════════════════${RESET}"
    echo -e "  ${GOLD}1)${RESET} ${BONE}Masuk Kembali ke Prompt Hermes${RESET} ${GREEN}(Chat Agent)${RESET}"
    echo -e "  ${GOLD}2)${RESET} ${BONE}Mode TUI Modern Hermes${RESET} ${GRAY}(hermes --tui)${RESET}"
    echo -e "  ${GOLD}3)${RESET} ${BONE}Pilih / Ganti Model Hermes${RESET} ${GRAY}(hermes model)${RESET}"
    echo -e "  ${GOLD}4)${RESET} ${BONE}Setup Wizard Hermes${RESET} ${GRAY}(hermes setup)${RESET}"
    echo -e "  ${GOLD}5)${RESET} ${CYAN}Konfigurasi Hermes${RESET} ${GRAY}(MCP, Integrasi, Tools)${RESET}"
    echo -e "  ${GOLD}6)${RESET} ${CYAN}Kelola 9router Gateway${RESET} ${GRAY}(Web UI / Log / Restart)${RESET}"
    echo -e "  ${GOLD}7)${RESET} ${YELLOW}Terminal Shell Container${RESET} ${GRAY}(docker exec bash)${RESET}"
    echo -e "  ${GOLD}8)${RESET} ${BONE}Terminal Shell Biasa${RESET} ${GRAY}(Bash Workspace)${RESET}"
    echo -e "  ${GOLD}0)${RESET} ${RED}Keluar & Matikan 9router${RESET}"
    echo ""
    read -r -p "Pilihan [0-8] (Default 1): " sub_opt
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
        hermes_config_menu "$container"
        ;;
      6)
        manage_9router_menu
        ;;
      7)
        docker exec -it -w /workspace "$container" bash || docker exec -it "$container" sh
        ;;
      8)
        start_shell
        return
        ;;
      0)
        echo -e "${YELLOW}[GaskenLE]${RESET} Mengakhiri sesi..."
        _cleanup_9router
        exit 0
        ;;
      *)
        docker exec -it -w /workspace "$container" /opt/hermes/bin/hermes
        ;;
    esac
  done
}

# ── Sprint 2: Hermes Configuration Menu (MCP, Integrations, Tools) ──
hermes_config_menu() {
  local container="$1"
  while true; do
    echo -e "\n${GOLD}═══════════════════════════════════════════════${RESET}"
    echo -e "${BONE}        🔧 KONFIGURASI HERMES AGENT             ${RESET}"
    echo -e "${GOLD}═══════════════════════════════════════════════${RESET}"
    echo -e "  ${GOLD}1)${RESET} ${BONE}Manajemen MCP Servers${RESET} ${GRAY}(tambah/hapus/lihat MCP)${RESET}"
    echo -e "  ${GOLD}2)${RESET} ${CYAN}Integrasi Discord Bot${RESET} ${GRAY}(token & channel ID)${RESET}"
    echo -e "  ${GOLD}3)${RESET} ${CYAN}Integrasi Telegram Bot${RESET} ${GRAY}(bot token & chat ID)${RESET}"
    echo -e "  ${GOLD}4)${RESET} ${BONE}Integrasi Notion${RESET} ${GRAY}(API key & workspace)${RESET}"
    echo -e "  ${GOLD}5)${RESET} ${YELLOW}Lihat Konfigurasi Aktif${RESET} ${GRAY}(hermes config list)${RESET}"
    echo -e "  ${GOLD}6)${RESET} ${RED}Reset Konfigurasi Hermes${RESET} ${GRAY}(hermes config reset)${RESET}"
    echo -e "  ${GOLD}0)${RESET} ${GRAY}Kembali ke Menu Utama${RESET}"
    echo ""
    read -r -p "Pilihan [0-6]: " cfg_opt
    case "$cfg_opt" in
      1) hermes_mcp_menu "$container" ;;
      2) hermes_discord_setup "$container" ;;
      3) hermes_telegram_setup "$container" ;;
      4) hermes_notion_setup "$container" ;;
      5)
        echo -e "\n${CYAN}--- Konfigurasi Hermes Aktif ---${RESET}"
        docker exec -it "$container" /opt/hermes/bin/hermes config list 2>/dev/null || \
          docker exec -it "$container" /opt/hermes/bin/hermes config show 2>/dev/null || \
          echo -e "${GRAY}(Gunakan: docker exec $container hermes config list)${RESET}"
        ;;
      6)
        echo -e "${RED}⚠ Ini akan menghapus seluruh config Hermes di container!${RESET}"
        read -r -p "Yakin? (yes/N): " confirm_reset
        if [ "$confirm_reset" = "yes" ]; then
          docker exec "$container" /opt/hermes/bin/hermes config reset 2>/dev/null || true
          echo -e "${GREEN}✓ Konfigurasi berhasil direset.${RESET}"
        fi
        ;;
      0) return ;;
      *) echo -e "${GRAY}Pilihan tidak valid.${RESET}" ;;
    esac
  done
}

hermes_mcp_menu() {
  local container="$1"
  while true; do
    echo -e "\n${GOLD}--- MCP SERVER MANAGER ---${RESET}"
    echo -e "  ${GOLD}1)${RESET} Lihat MCP Servers aktif"
    echo -e "  ${GOLD}2)${RESET} Tambah MCP Server (URL)"
    echo -e "  ${GOLD}3)${RESET} Tambah MCP Server via NPX package"
    echo -e "  ${GOLD}4)${RESET} Hapus MCP Server"
    echo -e "  ${GOLD}5)${RESET} Shell interaktif di container (kelola manual)"
    echo -e "  ${GOLD}0)${RESET} Kembali"
    echo ""
    read -r -p "Pilihan [0-5]: " mcp_opt
    case "$mcp_opt" in
      1)
        echo -e "${CYAN}MCP Servers:${RESET}"
        docker exec "$container" /opt/hermes/bin/hermes mcp list 2>/dev/null || \
          docker exec "$container" cat /root/.hermes/mcp.json 2>/dev/null || \
          echo -e "${GRAY}(Tidak ada MCP server terdaftar atau perintah tidak tersedia)${RESET}"
        ;;
      2)
        read -r -p "Nama server MCP: " mcp_name
        read -r -p "URL endpoint MCP (contoh: http://localhost:3001/sse): " mcp_url
        if [ -n "$mcp_name" ] && [ -n "$mcp_url" ]; then
          docker exec "$container" /opt/hermes/bin/hermes mcp add "$mcp_name" "$mcp_url" 2>/dev/null || \
            echo -e "${YELLOW}Coba tambahkan manual ke config MCP Hermes di container.${RESET}"
          echo -e "${GREEN}✓ MCP '$mcp_name' ditambahkan: $mcp_url${RESET}"
        fi
        ;;
      3)
        read -r -p "NPX Package MCP (contoh: @modelcontextprotocol/server-filesystem): " mcp_pkg
        if [ -n "$mcp_pkg" ]; then
          docker exec "$container" /opt/hermes/bin/hermes mcp add-npx "$mcp_pkg" 2>/dev/null || \
            echo -e "${YELLOW}Pastikan npx tersedia di container atau coba instalasi manual.${RESET}"
        fi
        ;;
      4)
        read -r -p "Nama MCP Server yang dihapus: " mcp_del
        if [ -n "$mcp_del" ]; then
          docker exec "$container" /opt/hermes/bin/hermes mcp remove "$mcp_del" 2>/dev/null || \
            echo -e "${YELLOW}Gagal menghapus, cek nama server yang benar.${RESET}"
          echo -e "${GREEN}✓ MCP '$mcp_del' dihapus.${RESET}"
        fi
        ;;
      5)
        echo -e "${GRAY}Membuka shell di container untuk kelola MCP secara manual...${RESET}"
        docker exec -it "$container" bash || docker exec -it "$container" sh
        ;;
      0) return ;;
    esac
  done
}

hermes_discord_setup() {
  local container="$1"
  echo -e "\n${CYAN}--- SETUP INTEGRASI DISCORD ---${RESET}"
  echo -e "${GRAY}Hermes dapat beroperasi sebagai Discord Bot menggunakan webhook atau bot token.${RESET}"
  echo -e "${GOLD}Referensi:${RESET} https://discord.com/developers/applications\n"
  read -r -p "Discord Bot Token: " discord_token
  read -r -p "Channel ID Target: " discord_channel
  if [ -n "$discord_token" ] && [ -n "$discord_channel" ]; then
    docker exec "$container" /opt/hermes/bin/hermes config set integrations.discord.token "$discord_token" 2>/dev/null || true
    docker exec "$container" /opt/hermes/bin/hermes config set integrations.discord.channel_id "$discord_channel" 2>/dev/null || true
    # Simpan juga ke .env lokal sebagai backup
    {
      echo "DISCORD_BOT_TOKEN=$discord_token"
      echo "DISCORD_CHANNEL_ID=$discord_channel"
    } >> "$WORKSPACE_DIR/.env"
    echo -e "${GREEN}✓ Konfigurasi Discord disimpan ke container & .env lokal.${RESET}"
  else
    echo -e "${YELLOW}Dibatalkan (input kosong).${RESET}"
  fi
}

hermes_telegram_setup() {
  local container="$1"
  echo -e "\n${CYAN}--- SETUP INTEGRASI TELEGRAM ---${RESET}"
  echo -e "${GRAY}Buat bot via @BotFather di Telegram, dapatkan token & chat_id.${RESET}"
  echo -e "${GOLD}Cek Chat ID:${RESET} https://api.telegram.org/bot<TOKEN>/getUpdates\n"
  read -r -p "Telegram Bot Token: " tg_token
  read -r -p "Chat ID Target: " tg_chat
  if [ -n "$tg_token" ] && [ -n "$tg_chat" ]; then
    docker exec "$container" /opt/hermes/bin/hermes config set integrations.telegram.token "$tg_token" 2>/dev/null || true
    docker exec "$container" /opt/hermes/bin/hermes config set integrations.telegram.chat_id "$tg_chat" 2>/dev/null || true
    {
      echo "TELEGRAM_BOT_TOKEN=$tg_token"
      echo "TELEGRAM_CHAT_ID=$tg_chat"
    } >> "$WORKSPACE_DIR/.env"
    echo -e "${GREEN}✓ Konfigurasi Telegram disimpan ke container & .env lokal.${RESET}"
  else
    echo -e "${YELLOW}Dibatalkan (input kosong).${RESET}"
  fi
}

hermes_notion_setup() {
  local container="$1"
  echo -e "\n${CYAN}--- SETUP INTEGRASI NOTION ---${RESET}"
  echo -e "${GRAY}Buat integration di: https://www.notion.so/my-integrations${RESET}"
  echo -e "${GRAY}Lalu share page/database yang ingin diakses ke integration tersebut.${RESET}\n"
  read -r -p "Notion API Key (secret_...): " notion_key
  read -r -p "Notion Workspace/Database ID (opsional): " notion_db
  if [ -n "$notion_key" ]; then
    docker exec "$container" /opt/hermes/bin/hermes config set integrations.notion.api_key "$notion_key" 2>/dev/null || true
    if [ -n "$notion_db" ]; then
      docker exec "$container" /opt/hermes/bin/hermes config set integrations.notion.database_id "$notion_db" 2>/dev/null || true
    fi
    {
      echo "NOTION_API_KEY=$notion_key"
      [ -n "$notion_db" ] && echo "NOTION_DATABASE_ID=$notion_db"
    } >> "$WORKSPACE_DIR/.env"
    echo -e "${GREEN}✓ Konfigurasi Notion disimpan ke container & .env lokal.${RESET}"
    echo -e "${GRAY}Tip: Pasang MCP server Notion agar Hermes bisa baca/tulis Notion secara agentic.${RESET}"
  else
    echo -e "${YELLOW}Dibatalkan (API key kosong).${RESET}"
  fi
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

# ── Auto-start 9router di background sejak awal ──
# Re-export PATH agar bun/npm ditemukan meski dijalankan dari tmux
export PATH="$HOME/.bun/bin:$HOME/.local/bin:$HOME/.npm-global/bin:$PATH"

if ! is_9router_running; then
  _NR_BIN=$(command -v 9router 2>/dev/null || true)
  if [ -n "$_NR_BIN" ]; then
    mkdir -p "$WORKSPACE_DIR/logs"
    (
      # WAJIB cd ke folder 9router agar config dibaca dengan benar
      cd "$NINEROUTER_DIR" 2>/dev/null || cd "$WORKSPACE_DIR"
      nohup "$_NR_BIN" -p "$NINEROUTER_PORT" -H "$NINEROUTER_HOST" -n --skip-update \
        </dev/null >"$WORKSPACE_DIR/logs/9router.log" 2>&1 &
      disown
    )
    _NINEROUTER_STARTED_BY_US=1
    # Tunggu hingga 3 detik sampai port terbuka
    for _i in 1 2 3 4 5 6; do
      sleep 0.5
      if is_9router_running; then
        echo -e "${GREEN}[9router] \u2713 Gateway aktif :${NINEROUTER_PORT}${RESET}"
        break
      fi
    done
    is_9router_running || echo -e "${GRAY}[9router] Booting... cek: logs/9router.log${RESET}"
  else
    echo -e "${YELLOW}[9router] Tidak ditemukan \u2014 pasang: bun add -g 9router${RESET}"
  fi
fi

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
    show_welcome_experience
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
